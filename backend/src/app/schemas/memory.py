from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class MasteryItem(BaseModel):
    concept_id: str
    concept_name: str
    confidence: float
    correct_count: int
    incorrect_count: int
    last_seen_at: datetime


class MemorySnapshot(BaseModel):
    items: list[MasteryItem]
    weak: list[str]  # concept ids
    preferred_style: str
