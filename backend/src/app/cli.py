"""CLI entry points. Kept out of app/db.py to avoid the __main__-vs-package
import duplication trap (where models register on a different Base than
the one create_all() walks).

Run as: `python -m app.cli init`
"""
from __future__ import annotations

import asyncio
import sys

from app.db import Base, engine
from app.models import concept, memory, quest, user  # noqa: F401  register tables


async def init_db() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    await engine.dispose()
    print("✓ tables created")


def main() -> None:
    if len(sys.argv) < 2:
        print("usage: python -m app.cli {init}")
        sys.exit(1)
    cmd = sys.argv[1]
    if cmd == "init":
        asyncio.run(init_db())
    else:
        print(f"unknown command: {cmd}")
        sys.exit(1)


if __name__ == "__main__":
    main()
