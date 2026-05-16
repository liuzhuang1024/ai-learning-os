# 架构决策记录

记录"为什么这样设计"，配合代码看才有意义。

## 1. Knowledge 与 Backend 解耦

`knowledge/` 是纯 YAML 数据，不是 Python 代码。

**为什么**：内容工作（写概念、出题、审稿）和工程工作（写 API、调模型）应该并行推进。如果概念嵌在代码里，每改一道题都要走代码 review。把它放到独立目录后：

- 内容审稿可以由不会 Python 的人做
- LLM 辅助生成的概念可以批量提交 PR，只 review YAML
- 同一份 knowledge 未来可以喂给 RAG、可视化、不同的客户端

## 2. Quest 内容半人工

概念解释由 LLM 生成（个性化），quiz 题目从 YAML 题库里抽（确定性、已审核）。

**为什么**：PRD §关键风险列了"Daily Quest 内容质量不稳定"是高风险。完全让 LLM 出题在 v0 阶段不可控（答案错、选项重复、难度抖动）。让 LLM 只负责"解释"这种容错率高的部分，关键事实交给人工题库。

第二阶段 LLM 可以从概念定义自动产出候选题，但仍走人工 review 才能进 quiz_bank。

## 3. Memory 只在 services 层写入

只有 `services/memory_service.record_answer` 能改 `concept_mastery`。Router 直接调 service，不直接 ORM。

**为什么**：mastery 是核心资产，写入逻辑（衰减曲线、上下限、未来的间隔重复触发）必须收口在一处。绕过 service 直接写 DB 会让规则散落。

## 4. v0 假认证

Router 通过 `X-User-Id` header 取 user_id，没有真正的 JWT。

**为什么**：6 周 MVP 要先验留存，不验证账号系统。Onboarding 之后客户端拿到一个 user_id 自己存好，全链路用它。真要上内测前 1 周再补 JWT。

## 5. async-first

SQLAlchemy 2.x async + asyncpg + FastAPI 异步路由。

**为什么**：LLM 调用是 IO bound 大头，单条响应 2–10 秒。同步框架会让 worker 阻塞，并发用户数受限。早期就上 async，免得后期重写。

## 6. 不用 alembic for dev

`python -m app.db init` 走 `create_all`。

**为什么**：节点 schema 在 6 周内会反复改，alembic 反而成负担。M5 之前删库重建是常态。alembic 在 M5 后接入。

## 7. Anthropic 主 + Qwen 备的接口设计

`services/llm.py` 是单一入口；v0 只接 Anthropic，但 `complete()` 签名预留了切换点。

**为什么**：避免在还没需要的时候做多模型抽象，但要让"以后接 Qwen"是一次性的局部改动，不是全局重构。
