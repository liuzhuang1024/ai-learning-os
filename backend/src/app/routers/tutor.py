from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.routers.deps import current_user_id
from app.schemas.tutor import ChatIn, ChatOut
from app.services import tutor

router = APIRouter(prefix="/tutor", tags=["tutor"])


@router.post("/chat", response_model=ChatOut)
async def chat(
    body: ChatIn,
    user_id: uuid.UUID = Depends(current_user_id),
    session: AsyncSession = Depends(get_session),
) -> ChatOut:
    history = [m.model_dump() for m in body.history]
    reply = await tutor.reply(session, user_id, history, body.message)
    return ChatOut(reply=reply)
