"""In-memory representation of a knowledge graph node.

Note: concept metadata lives in `knowledge/nodes/*.yaml`, NOT in the DB.
This file only defines the in-memory dataclass used by services.
The DB only stores user-specific state (mastery, quests).
"""
from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class QuizQuestion:
    question: str
    options: list[str]
    answer_index: int
    explanation: str


@dataclass
class ConceptMeta:
    id: str
    name: str
    category: str  # math | python | ml | dl | nlp | cv | mlops
    difficulty: int  # 1..5
    prerequisites: list[str] = field(default_factory=list)
    definition: str = ""
    analogy: str = ""
    formula: str = ""
    code_example: str = ""
    quiz_bank: list[QuizQuestion] = field(default_factory=list)
