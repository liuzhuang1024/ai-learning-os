from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.knowledge.loader import get_graph
from app.models.memory import UserProfile
from app.routers.deps import current_user_id
from app.schemas.memory import MasteryItem, MemorySnapshot
from app.services import memory_service

router = APIRouter(prefix="/memory", tags=["memory"])


@router.get("", response_model=MemorySnapshot)
async def get_memory(
    user_id: uuid.UUID = Depends(current_user_id),
    session: AsyncSession = Depends(get_session),
) -> MemorySnapshot:
    graph = get_graph()
    items = await memory_service.snapshot(session, user_id)
    weak = await memory_service.weak_concepts(session, user_id)
    profile = await session.get(UserProfile, user_id)
    return MemorySnapshot(
        items=[
            MasteryItem(
                concept_id=m.concept_id,
                concept_name=graph[m.concept_id].name if m.concept_id in graph else m.concept_id,
                confidence=m.confidence,
                correct_count=m.correct_count,
                incorrect_count=m.incorrect_count,
                last_seen_at=m.last_seen_at,
            )
            for m in items
        ],
        weak=[m.concept_id for m in weak],
        preferred_style=(profile.preferred_style if profile else "mixed"),
    )
