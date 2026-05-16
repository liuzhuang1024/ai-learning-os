"""Pick the next concept to study and assemble a Quest.

Selection priority (in order):
1. A weak concept (mastery < 0.4) that the user has seen — spaced repetition.
2. A concept whose prerequisites are all at confidence > 0.6 and that
   the user has not seen yet — frontier expansion.
3. The lowest-difficulty unseen concept — fallback when memory is empty.

The Quest payload itself is assembled from the concept's authored
`quiz_bank` (deterministic, reviewed) plus a one-shot LLM call for the
explanation tailored to the user's preferred style.
"""
from __future__ import annotations

import logging
import random
import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.knowledge.loader import get_graph
from app.models.concept import ConceptMeta
from app.models.memory import ConceptMastery, UserProfile
from app.models.quest import DailyQuest, QuestStatus
from app.services.llm import get_llm

log = logging.getLogger(__name__)

_WEAK_THRESHOLD = 0.4
_PREREQ_THRESHOLD = 0.6
_QUIZ_SIZE = 2


async def _get_or_create_today(session: AsyncSession, user_id: uuid.UUID) -> DailyQuest | None:
    today = date.today()
    stmt = select(DailyQuest).where(DailyQuest.user_id == user_id, DailyQuest.date == today)
    return (await session.execute(stmt)).scalar_one_or_none()


async def _user_mastery(session: AsyncSession, user_id: uuid.UUID) -> dict[str, ConceptMastery]:
    stmt = select(ConceptMastery).where(ConceptMastery.user_id == user_id)
    rows = (await session.execute(stmt)).scalars().all()
    return {m.concept_id: m for m in rows}


def _select_concept(
    graph: dict[str, ConceptMeta], mastery: dict[str, ConceptMastery]
) -> ConceptMeta | None:
    # 1. Weak + seen
    weak = [
        graph[c.concept_id]
        for c in mastery.values()
        if c.confidence < _WEAK_THRESHOLD and c.concept_id in graph
    ]
    if weak:
        return min(weak, key=lambda n: n.difficulty)

    # 2. Frontier: prereqs satisfied, concept itself unseen.
    candidates: list[ConceptMeta] = []
    for node in graph.values():
        if node.id in mastery:
            continue
        if all(
            (mastery.get(p) and mastery[p].confidence >= _PREREQ_THRESHOLD)
            for p in node.prerequisites
        ):
            candidates.append(node)
    if candidates:
        return min(candidates, key=lambda n: n.difficulty)

    # 3. Fallback: easiest unseen concept with no prereqs.
    fallback = [n for n in graph.values() if n.id not in mastery and not n.prerequisites]
    if fallback:
        return min(fallback, key=lambda n: n.difficulty)

    return None


async def _generate_explanation(
    concept: ConceptMeta, profile: UserProfile | None, user_id: uuid.UUID
) -> str:
    style = (profile.preferred_style if profile else "mixed") or "mixed"
    background = (profile.background_summary if profile else "") or "无背景信息"

    system = (
        "你是一位 AI 学习导师，正在为一位 AI 转型者讲解一个核心概念。"
        "讲解必须紧扣他们的背景，避免泛泛而谈，限 200 字以内。"
    )
    user_msg = (
        f"今日概念：{concept.name}\n"
        f"用户背景：{background}\n"
        f"用户偏好风格：{style}\n\n"
        f"已有定义：{concept.definition}\n"
        f"类比：{concept.analogy}\n\n"
        "请用一段话讲解此概念，结合用户背景给出 1 个具体的迁移例子。"
    )
    llm = get_llm()
    resp = await llm.complete(
        system=system,
        messages=[{"role": "user", "content": user_msg}],
        max_tokens=500,
        user_id=str(user_id),
    )
    return resp.text


async def ensure_today_quest(session: AsyncSession, user_id: uuid.UUID) -> DailyQuest | None:
    """Idempotent: returns today's Quest, generating it if missing."""
    existing = await _get_or_create_today(session, user_id)
    if existing:
        return existing

    graph = get_graph()
    if not graph:
        log.warning("knowledge graph is empty; cannot generate quest")
        return None

    mastery = await _user_mastery(session, user_id)
    concept = _select_concept(graph, mastery)
    if concept is None:
        log.info("no concept available for user %s", user_id)
        return None

    profile = await session.get(UserProfile, user_id)
    explanation = await _generate_explanation(concept, profile, user_id)

    # Pick quiz questions deterministically-ish: shuffle bank, take N.
    bank = list(concept.quiz_bank)
    random.shuffle(bank)
    quiz_payload = [
        {
            "question": q.question,
            "options": q.options,
            "answer_index": q.answer_index,
            "explanation": q.explanation,
        }
        for q in bank[:_QUIZ_SIZE]
    ]

    practice_payload = {"type": "code" if concept.code_example else "thought", "prompt": concept.code_example or concept.analogy}

    quest = DailyQuest(
        user_id=user_id,
        date=date.today(),
        concept_id=concept.id,
        explanation=explanation,
        quiz_payload=quiz_payload,
        practice_payload=practice_payload,
        status=QuestStatus.pending.value,
    )
    session.add(quest)
    await session.flush()
    return quest
