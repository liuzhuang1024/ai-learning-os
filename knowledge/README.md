# Knowledge Graph

Hand-curated AI/ML concept nodes. **This is the early moat** — not the LLM, not the code.

Each YAML file under `nodes/` is one concept. The backend loads them all at startup.

## Schema

```yaml
id: math_vectors                      # snake_case, globally unique
name: 向量与点积                       # human-readable, shown in UI
category: math                        # math | python | ml | dl | nlp | cv | mlops
difficulty: 1                         # 1..5
prerequisites: []                     # list of other concept ids
definition: |                         # 1-2 sentence formal definition
  ...
analogy: |                            # plain-language analogy
  ...
formula: |                            # optional, LaTeX
  ...
code_example: |                       # optional, Python snippet
  ...
quiz_bank:                            # 3+ questions per node, reviewed before merge
  - question: ...
    options: [A, B, C, D]
    answer_index: 0                   # 0-based
    explanation: ...
```

## 编辑流程

1. 新建 `nodes/<concept_id>.yaml`，按上面的 schema 写
2. 至少写 3 道 quiz（这是审核质量的核心 —— 题目质量决定一切）
3. 重启 backend，或调用 `/dev/reload-knowledge`（待实现）

## 当前节点（W1 目标：30 个）

```
math_vectors           向量与点积
python_basics          Python 基础语法
ml_supervised          监督学习核心思想
```

剩余 27 个待补充。优先级：先把"30 个 AI 转型者必懂的概念"列全，再每个写 3 道题。
