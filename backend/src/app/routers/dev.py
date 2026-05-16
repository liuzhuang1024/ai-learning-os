"""Dev-only endpoints. Mounted only when APP_ENV=dev.

These bypass auth and let us drive the system from curl / scripts before
real account flows are wired up.
"""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.knowledge.loader import reload_graph
from app.models.user import User

router = APIRouter(prefix="/dev", tags=["dev"])


@router.post("/seed-user")
async def seed_user(session: AsyncSession = Depends(get_session)) -> dict:
    """Create a throwaway User row and return its id.

    Use the returned id as the X-User-Id header for subsequent calls.
    """
    user = User(
        email=f"dev-{uuid.uuid4().hex[:8]}@local",
        display_name="dev user",
        hashed_password="!unset",
    )
    session.add(user)
    await session.commit()
    return {"user_id": str(user.id), "email": user.email}


@router.post("/reload-knowledge")
async def reload_knowledge() -> dict:
    """Hot-reload knowledge/nodes/*.yaml without restarting the server."""
    count = reload_graph()
    return {"loaded": count}
