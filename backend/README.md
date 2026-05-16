# Backend

FastAPI + SQLAlchemy 2 (async) + PostgreSQL.

## 启动

```bash
# 1. 安装依赖
uv sync

# 2. 配置环境
cp .env.example .env
# 编辑 .env，填入 ANTHROPIC_API_KEY、DATABASE_URL 等

# 3. 起一个本地 Postgres（任选其一）
docker run -d --name learning-os-pg -p 5432:5432 \
  -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=learning_os postgres:16

# 4. 初始化数据库（alembic 暂未生成 migrations，开发期先用 create_all）
uv run python -m app.db init

# 5. 启动
uv run uvicorn app.main:app --reload --port 8000
```

打开 http://localhost:8000/docs 查看 API。

## 目录

```
src/app/
├── main.py            FastAPI 入口
├── config.py          配置（pydantic-settings）
├── db.py              SQLAlchemy 引擎/Session
├── models/            ORM 模型
│   ├── user.py        用户
│   ├── memory.py      ConceptMastery + UserProfile (Learning Memory)
│   └── quest.py       DailyQuest + QuizAttempt
├── schemas/           Pydantic 请求/响应 schema
├── routers/
│   ├── onboarding.py  入门诊断
│   ├── quest.py       Daily Quest
│   ├── tutor.py       Tutor Agent 对话
│   └── memory.py      用户学习记忆快照
├── services/
│   ├── llm.py            LLM 客户端（Anthropic 主、Qwen 备）
│   ├── assessment.py     自适应诊断逻辑
│   ├── quest_generator.py 根据 mastery + 知识图谱选下一个概念
│   ├── memory_service.py  Mastery 更新规则
│   └── tutor.py          对话 context 构建
└── knowledge/
    └── loader.py      启动时加载 knowledge/nodes/*.yaml
```

## 设计要点

- **Memory 是核心**：每次 quiz 答题、每次对话都会更新 `ConceptMastery`。这是个性化的唯一真相源。
- **Knowledge 是数据，不是代码**：人工维护的 YAML 文件放在 `knowledge/`，后端启动时加载到内存。改概念不用改代码。
- **LLM 调用都过 services/llm.py**：方便切模型、加缓存、统计 token。
- **Quest 内容初期半人工**：v1 阶段每个 concept 自带题库（写在 YAML 里），LLM 只负责生成解释和补充练习。
