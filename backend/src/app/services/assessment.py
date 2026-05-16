"""Onboarding assessment.

MVP version: not adaptive. A fixed bank of 10 questions spanning math /
python / ml. Future: serve next question based on prior answers (IRT or
a simple ladder).
"""
from __future__ import annotations

import uuid
from dataclasses import dataclass

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.memory import UserProfile
from app.services.memory_service import record_answer


@dataclass
class AssessmentQuestion:
    id: str
    concept_id: str
    question: str
    options: list[str]
    answer_index: int


# In v0 these are hand-authored. Later: pull from concept quiz_bank tagged "assessment".
ASSESSMENT_BANK: list[AssessmentQuestion] = [
    AssessmentQuestion(
        id="a1",
        concept_id="math_vectors",
        question="两个向量的点积结果是什么类型？",
        options=["标量", "向量", "矩阵", "张量"],
        answer_index=0,
    ),
    AssessmentQuestion(
        id="a2",
        concept_id="python_basics",
        question="Python 中 list comprehension 的语法是？",
        options=["[x for x in iterable]", "{x : x in iterable}", "(x; x in iterable)", "list(x in iterable)"],
        answer_index=0,
    ),
    AssessmentQuestion(
        id="a3",
        concept_id="ml_supervised",
        question="监督学习的核心区别于无监督学习的是什么？",
        options=["有标签", "数据量大", "模型复杂", "训练时间长"],
        answer_index=0,
    ),
]


def get_questions() -> list[AssessmentQuestion]:
    return ASSESSMENT_BANK


async def submit_results(
    session: AsyncSession,
    user_id: uuid.UUID,
    answers: dict[str, int],
    background_summary: str,
    preferred_style: str,
) -> UserProfile:
    """Record assessment answers as initial mastery + create/update profile."""
    by_id = {q.id: q for q in ASSESSMENT_BANK}
    for qid, choice in answers.items():
        q = by_id.get(qid)
        if q is None:
            continue
        await record_answer(session, user_id, q.concept_id, choice == q.answer_index)

    profile = await session.get(UserProfile, user_id)
    if profile is None:
        profile = UserProfile(
            user_id=user_id,
            preferred_style=preferred_style,
            background_summary=background_summary,
        )
        session.add(profile)
    else:
        profile.preferred_style = preferred_style
        profile.background_summary = background_summary

    await session.flush()
    return profile
