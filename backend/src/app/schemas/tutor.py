from __future__ import annotations

from pydantic import BaseModel


class Message(BaseModel):
    role: str  # "user" | "assistant"
    content: str


class ChatIn(BaseModel):
    history: list[Message] = []
    message: str


class ChatOut(BaseModel):
    reply: str
