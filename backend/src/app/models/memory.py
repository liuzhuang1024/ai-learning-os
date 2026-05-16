"""Learning Memory — the user's mastery state and stylistic preferences.

This is the system's most important persistent state. Everything else (Quest
selection, Tutor context) is derived from these tables.
"""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import JSON, DateTime, Float, ForeignKey, Integer, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class ConceptMastery(Base):
    """Per-user, per-concept mastery state.

    `confidence` is a 0–1 scalar combining: recency, correct/incorrect ratio,
    and self-reported confidence after explanations. Updated by
    services.memory_service on every quiz answer and tutor interaction.
    """

    __tablename__ = "concept_mastery"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    concept_id: Mapped[str] = mapped_column(String(80), primary_key=True)

    confidence: Mapped[float] = mapped_column(Float, default=0.0)
    correct_count: Mapped[int] = mapped_column(Integer, default=0)
    incorrect_count: Mapped[int] = mapped_column(Integer, default=0)
    last_seen_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class UserProfile(Base):
    """Style + rhythm preferences. One row per user."""

    __tablename__ = "user_profiles"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    # one of: analogy | code | formula | mixed
    preferred_style: Mapped[str] = mapped_column(String(20), default="mixed")
    background_summary: Mapped[str] = mapped_column(String(2000), default="")
    # Activity histogram by hour: {"0": 0, "1": 0, ..., "23": 5}
    active_hours: Mapped[dict] = mapped_column(JSON, default=dict)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
