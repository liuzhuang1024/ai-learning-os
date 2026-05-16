"""Tutor Agent — chat backed by the user's Learning Memory.

The key thing that makes this not-a-generic-chatbot: every call assembles
a system prompt that includes (a) the user's preferred style, (b) their
weakest concepts, (c) their most recent Quest. The LLM is given context
that no general assistant has.
"""
from __future__ import annotations

import uuid
from datetime import date, timedelta

from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.knowledge.loader import get_graph
from app.models.memory import UserProfile
from app.models.quest import DailyQuest
from app.services import memory_service
from app.services.llm import get_llm

_SYSTEM_TEMPLATE = """你是用户的个人 AI 学习导师。你和普通 AI 助手的关键区别是：你**记得用户学到哪里了**。

用户背景：{background}
用户偏好的解释风格：{style}

用户最近 7 天的薄弱概念（按掌握度由低到高）：
{weak_list}

用户今日学习内容：{today_topic}

行为准则：
- 主动联系用户已学过的内容，避免脱离上下文
- 当用户问基础问题时，用类比或代码示例（按其偏好）
- 当用户问超出当前阶段的问题时，温和地引导回到目标，不要回避
- 回答简洁，单轮限 250 字以内；用户追问再展开
"""


async def build_context(session: AsyncSession, user_id: uuid.UUID) -> str:
    profile = await session.get(UserProfile, user_id)
    background = (profile.background_summary if profile else "") or "未提供"
    style = (profile.preferred_style if profile else "mixed") or "mixed"

    weak = await memory_service.weak_concepts(session, user_id, limit=5)
    graph = get_graph()
    weak_list = (
        "\n".join(
            f"- {graph[w.concept_id].name if w.concept_id in graph else w.concept_id}"
            f"（掌握度 {w.confidence:.2f}）"
            for w in weak
        )
        or "（暂无数据）"
    )

    since = date.today() - timedelta(days=1)
    recent_stmt = (
        select(DailyQuest)
        .where(DailyQuest.user_id == user_id, DailyQuest.date >= since)
        .order_by(desc(DailyQuest.date))
        .limit(1)
    )
    recent = (await session.execute(recent_stmt)).scalar_one_or_none()
    today_topic = (
        graph[recent.concept_id].name
        if recent and recent.concept_id in graph
        else "（今日还未开始）"
    )

    return _SYSTEM_TEMPLATE.format(
        background=background,
        style=style,
        weak_list=weak_list,
        today_topic=today_topic,
    )


async def reply(
    session: AsyncSession,
    user_id: uuid.UUID,
    history: list[dict],
    user_message: str,
) -> str:
    """history is a list of {"role": "user"|"assistant", "content": str}."""
    system = await build_context(session, user_id)
    messages = [*history, {"role": "user", "content": user_message}]
    resp = await get_llm().complete(
        system=system, messages=messages, max_tokens=600, user_id=str(user_id)
    )
    return resp.text
