from __future__ import annotations

from pydantic import BaseModel, Field


class AssessmentQuestionOut(BaseModel):
    id: str
    question: str
    options: list[str]


class AssessmentStart(BaseModel):
    questions: list[AssessmentQuestionOut]


class AssessmentSubmit(BaseModel):
    answers: dict[str, int] = Field(description="map of question_id -> selected option index")
    background_summary: str
    preferred_style: str = Field(default="mixed", pattern="^(analogy|code|formula|mixed)$")


class AssessmentResult(BaseModel):
    starting_concepts: list[str]
    summary: str
