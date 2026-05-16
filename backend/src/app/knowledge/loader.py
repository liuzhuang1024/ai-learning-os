"""Load knowledge graph nodes from YAML files at startup.

Each YAML file under `knowledge/nodes/` defines one concept. See
`knowledge/README.md` for the schema. Files are read once on startup and
held in memory; restart the server to pick up changes.

If you need hot-reload during content authoring, call `reload_graph()`
from a dev endpoint.
"""
from __future__ import annotations

import logging
from pathlib import Path

import yaml

from app.config import get_settings
from app.models.concept import ConceptMeta, QuizQuestion

log = logging.getLogger(__name__)

_GRAPH: dict[str, ConceptMeta] = {}


def _parse_node(data: dict) -> ConceptMeta:
    quiz_bank = [
        QuizQuestion(
            question=q["question"],
            options=q["options"],
            answer_index=q["answer_index"],
            explanation=q.get("explanation", ""),
        )
        for q in data.get("quiz_bank", [])
    ]
    return ConceptMeta(
        id=data["id"],
        name=data["name"],
        category=data["category"],
        difficulty=data.get("difficulty", 1),
        prerequisites=data.get("prerequisites", []),
        definition=data.get("definition", ""),
        analogy=data.get("analogy", ""),
        formula=data.get("formula", ""),
        code_example=data.get("code_example", ""),
        quiz_bank=quiz_bank,
    )


def load_graph(root: Path | None = None) -> dict[str, ConceptMeta]:
    global _GRAPH
    root = root or get_settings().knowledge_path
    if not root.is_absolute():
        # Resolve relative to the backend/ dir (this file is in src/app/knowledge/).
        root = (Path(__file__).resolve().parents[3] / root).resolve()

    if not root.exists():
        log.warning("knowledge path does not exist: %s", root)
        _GRAPH = {}
        return _GRAPH

    graph: dict[str, ConceptMeta] = {}
    for path in sorted(root.glob("*.yaml")):
        with path.open() as f:
            node = _parse_node(yaml.safe_load(f))
        if node.id in graph:
            raise ValueError(f"duplicate concept id {node.id} (in {path})")
        graph[node.id] = node

    # Validate prerequisite references.
    for node in graph.values():
        for prereq in node.prerequisites:
            if prereq not in graph:
                raise ValueError(f"concept {node.id} has unknown prerequisite {prereq}")

    log.info("loaded %d concepts from %s", len(graph), root)
    _GRAPH = graph
    return graph


def get_graph() -> dict[str, ConceptMeta]:
    if not _GRAPH:
        load_graph()
    return _GRAPH


def reload_graph() -> int:
    load_graph()
    return len(_GRAPH)
