# AI Research Learning OS

为 AI 转型者打造的学习陪伴系统 —— 知道你学到哪了，每天推着你往前走的 AI 导师。

完整产品文档见 [docs/PRD-v2.md](docs/PRD-v2.md)。

## 仓库结构

```
.
├── backend/      FastAPI + SQLAlchemy（用户、记忆、Quest、Tutor API）
├── mobile/       Flutter 应用（iOS + Android）
├── knowledge/    精选的 AI/ML 概念知识图谱（YAML，人工编辑）
└── docs/         产品文档、设计决策
```

三者解耦：knowledge/ 是纯数据，backend/ 在启动时加载它，mobile/ 通过 HTTP 调用 backend。

## 快速开始

后端：见 [backend/README.md](backend/README.md)

移动端：见 [mobile/README.md](mobile/README.md)

知识库：见 [knowledge/README.md](knowledge/README.md)

## 当前状态

MVP 阶段，参考 PRD 的 6 周里程碑。唯一要验证的假设是「用户愿意每天打开这个 App」。
