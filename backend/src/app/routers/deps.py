"""Shared route dependencies.

NOTE: `current_user_id` is a placeholder for v0 — it reads an X-User-Id
header so the API is usable from curl/Flutter without auth wired up.
Replace with real JWT auth before any real users see this.
"""
from __future__ import annotations

import uuid

from fastapi import Header, HTTPException, status


async def current_user_id(x_user_id: str | None = Header(default=None)) -> uuid.UUID:
    if not x_user_id:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "missing X-User-Id header")
    try:
        return uuid.UUID(x_user_id)
    except ValueError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "invalid user id") from e
