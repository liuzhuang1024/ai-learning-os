"""Smoke tests that don't require DB/LLM. Run with `uv run pytest`."""
from __future__ import annotations

from app.knowledge.loader import load_graph
from app.models.concept import ConceptMeta
from app.services.quest_generator import _select_concept


def test_load_graph_seed():
    graph = load_graph()
    assert len(graph) >= 3, "seed knowledge graph should have at least 3 nodes"
    for node in graph.values():
        assert isinstance(node, ConceptMeta)
        for prereq in node.prerequisites:
            assert prereq in graph


def test_select_concept_empty_mastery_returns_no_prereq_node():
    graph = load_graph()
    pick = _select_concept(graph, mastery={})
    assert pick is not None
    assert not pick.prerequisites, "first pick for new user must have no prerequisites"
