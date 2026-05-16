from __future__ import annotations

import uuid
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.models.quest import DailyQuest, QuestStatus, QuizAttempt
from app.routers.deps import current_user_id
from app.schemas.quest import AnswerIn, AnswerOut, PracticeOut, QuestOut, QuizQuestionOut
from app.services import memory_service
from app.services.quest_generator import ensure_today_quest

router = APIRouter(prefix="/quest", tags=["quest"])


def _to_out(q: DailyQuest) -> QuestOut:
    return QuestOut(
        id=q.id,
        date=q.date,
        concept_id=q.concept_id,
        explanation=q.explanation,
        # Strip answer_index/explanation from the response — clients learn nothing.
        quiz=[QuizQuestionOut(question=item["question"], options=item["options"]) for item in q.quiz_payload],
        practice=PracticeOut(**q.practice_payload) if q.practice_payload else PracticeOut(type="thought", prompt=""),
        status=q.status,
        completed_at=q.completed_at,
    )


@router.get("/today", response_model=QuestOut)
async def get_today(
    user_id: uuid.UUID = Depends(current_user_id),
    session: AsyncSession = Depends(get_session),
) -> QuestOut:
    quest = await ensure_today_quest(session, user_id)
    if quest is None:
        raise HTTPException(503, "knowledge graph empty or no candidate concept available")
    await session.commit()
    return _to_out(quest)


@router.post("/{quest_id}/answer", response_model=AnswerOut)
async def submit_answer(
    quest_id: uuid.UUID,
    body: AnswerIn,
    user_id: uuid.UUID = Depends(current_user_id),
    session: AsyncSession = Depends(get_session),
) -> AnswerOut:
    quest = await session.get(DailyQuest, quest_id)
    if quest is None or quest.user_id != user_id:
        raise HTTPException(404, "quest not found")
    if body.question_index < 0 or body.question_index >= len(quest.quiz_payload):
        raise HTTPException(400, "question_index out of range")

    question = quest.quiz_payload[body.question_index]
    is_correct = body.choice_index == question["answer_index"]

    session.add(
        QuizAttempt(
            quest_id=quest.id,
            question_index=body.question_index,
            user_answer=str(body.choice_index),
            is_correct=is_correct,
        )
    )
    await memory_service.record_answer(session, user_id, quest.concept_id, is_correct)

    # When all questions are answered, mark Quest complete.
    answered_count = body.question_index + 1  # rough proxy; refine with a real count query later
    if answered_count >= len(quest.quiz_payload):
        quest.status = QuestStatus.completed.value
        quest.completed_at = datetime.now(UTC)

    await session.commit()
    return AnswerOut(
        is_correct=is_correct,
        correct_index=question["answer_index"],
        explanation=question.get("explanation", ""),
    )
