from __future__ import annotations

import uuid
from datetime import date, datetime

from pydantic import BaseModel


class QuizQuestionOut(BaseModel):
    question: str
    options: list[str]


class PracticeOut(BaseModel):
    type: str
    prompt: str


class QuestOut(BaseModel):
    id: uuid.UUID
    date: date
    concept_id: str
    explanation: str
    quiz: list[QuizQuestionOut]
    practice: PracticeOut
    status: str
    completed_at: datetime | None = None


class AnswerIn(BaseModel):
    question_index: int
    choice_index: int


class AnswerOut(BaseModel):
    is_correct: bool
    correct_index: int
    explanation: str
