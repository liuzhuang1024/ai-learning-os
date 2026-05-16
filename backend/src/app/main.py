from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.config import get_settings
from app.knowledge.loader import load_graph
from app.routers import dev, memory, onboarding, quest, tutor

logging.basicConfig(level=get_settings().log_level)
log = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    graph = load_graph()
    log.info("knowledge graph loaded: %d concepts", len(graph))
    yield


app = FastAPI(title="AI Learning OS", version="0.1.0", lifespan=lifespan)
app.include_router(onboarding.router)
app.include_router(quest.router)
app.include_router(tutor.router)
app.include_router(memory.router)

# Dev endpoints (seed-user, reload-knowledge) — production builds never see them.
if get_settings().app_env == "dev":
    app.include_router(dev.router)


@app.get("/health")
async def health() -> dict:
    return {"ok": True}
