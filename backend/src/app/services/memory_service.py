"""Learning Memory updates.

Single place that mutates `ConceptMastery`. Every signal (quiz answer, tutor
self-rating, spaced-repetition recall) eventually lands here.
"""
from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.memory import ConceptMastery

# Tunable in one place — keep the curve gentle so a single wrong answer
# doesn't tank the user's perceived progress.
_CORRECT_WEIGHT = 0.15
_INCORRECT_WEIGHT = 0.20
_MAX_CONFIDENCE = 1.0


async def record_answer(
    session: AsyncSession,
    user_id: uuid.UUID,
    concept_id: str,
    is_correct: bool,
) -> ConceptMastery:
    """Update mastery for one (user, concept) pair based on a single quiz outcome.

    Confidence is bounded to [0, 1]. Correct answers nudge up, incorrect nudge
    down — both by small fixed weights so the system doesn't oscillate.
    """
    stmt = select(ConceptMastery).where(
        ConceptMastery.user_id == user_id,
        ConceptMastery.concept_id == concept_id,
    )
    mastery = (await session.execute(stmt)).scalar_one_or_none()

    if mastery is None:
        # Set counters explicitly: column `default=0` only applies at INSERT,
        # so before flush the attrs would be None and `+= 1` would TypeError.
        mastery = ConceptMastery(
            user_id=user_id,
            concept_id=concept_id,
            confidence=0.0,
            correct_count=0,
            incorrect_count=0,
        )
        session.add(mastery)

    if is_correct:
        mastery.correct_count += 1
        mastery.confidence = min(_MAX_CONFIDENCE, mastery.confidence + _CORRECT_WEIGHT)
    else:
        mastery.incorrect_count += 1
        mastery.confidence = max(0.0, mastery.confidence - _INCORRECT_WEIGHT)

    await session.flush()
    return mastery


async def snapshot(session: AsyncSession, user_id: uuid.UUID) -> list[ConceptMastery]:
    stmt = select(ConceptMastery).where(ConceptMastery.user_id == user_id)
    return list((await session.execute(stmt)).scalars().all())


async def weak_concepts(
    session: AsyncSession, user_id: uuid.UUID, threshold: float = 0.4, limit: int = 5
) -> list[ConceptMastery]:
    """Return the user's lowest-confidence concepts they've seen at least once."""
    stmt = (
        select(ConceptMastery)
        .where(
            ConceptMastery.user_id == user_id,
            ConceptMastery.confidence < threshold,
            ConceptMastery.incorrect_count + ConceptMastery.correct_count > 0,
        )
        .order_by(ConceptMastery.confidence.asc())
        .limit(limit)
    )
    return list((await session.execute(stmt)).scalars().all())
