from __future__ import annotations

import uuid
from datetime import UTC, datetime

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.routers.deps import current_user_id
from app.schemas.onboarding import (
    AssessmentQuestionOut,
    AssessmentResult,
    AssessmentStart,
    AssessmentSubmit,
)
from app.services import assessment
from app.services.memory_service import snapshot

router = APIRouter(prefix="/onboarding", tags=["onboarding"])


@router.get("/assessment", response_model=AssessmentStart)
async def start_assessment() -> AssessmentStart:
    return AssessmentStart(
        questions=[
            AssessmentQuestionOut(id=q.id, question=q.question, options=q.options)
            for q in assessment.get_questions()
        ]
    )


@router.post("/assessment", response_model=AssessmentResult)
async def submit_assessment(
    body: AssessmentSubmit,
    user_id: uuid.UUID = Depends(current_user_id),
    session: AsyncSession = Depends(get_session),
) -> AssessmentResult:
    profile = await assessment.submit_results(
        session,
        user_id=user_id,
        answers=body.answers,
        background_summary=body.background_summary,
        preferred_style=body.preferred_style,
    )
    # Mark onboarding complete on the user row.
    from app.models.user import User  # local import to avoid cycle in tests

    user = await session.get(User, user_id)
    if user is not None:
        user.onboarding_completed_at = datetime.now(UTC)
    await session.commit()

    items = await snapshot(session, user_id)
    return AssessmentResult(
        starting_concepts=[m.concept_id for m in items],
        summary=f"已记录 {len(items)} 个起点概念；偏好风格：{profile.preferred_style}",
    )
