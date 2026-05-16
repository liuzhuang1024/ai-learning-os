"""Async SQLAlchemy engine + session.

Run `python -m app.db init` to create all tables for dev. Use alembic in prod.
"""
from __future__ import annotations

import asyncio
import sys
from collections.abc import AsyncIterator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.config import get_settings


class Base(DeclarativeBase):
    pass


_settings = get_settings()
engine = create_async_engine(_settings.database_url, echo=False, pool_pre_ping=True)
SessionLocal = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)


async def get_session() -> AsyncIterator[AsyncSession]:
    async with SessionLocal() as session:
        yield session


async def _init_db() -> None:
    # Import models so they register on Base.metadata before create_all.
    from app.models import concept, memory, quest, user  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print("✓ tables created")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "init":
        asyncio.run(_init_db())
    else:
        print("usage: python -m app.db init")
