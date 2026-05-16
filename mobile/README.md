# Mobile (Flutter)

iOS + Android. Mobile-first because学习行为是高频碎片化的——见 PRD §产品形态。

## 现状

**未 bootstrap**。Flutter SDK 还没装。`lib/` 里有目录结构和占位文件，描述了我们要构建的页面/服务划分。

## 安装 Flutter 后的接入步骤

```bash
# 1. 装 Flutter
brew install --cask flutter
flutter doctor      # 按提示安装 Xcode / Android Studio

# 2. 在本目录初始化项目（保留现有 lib/）
cd mobile
flutter create --org com.learningos --project-name learning_os .
# create 会试图覆盖 lib/main.dart，回答 N 保留我们的占位

# 3. 拉依赖
flutter pub get

# 4. 起后端，然后跑 app
# 在另一个终端：cd ../backend && uv run uvicorn app.main:app --reload
flutter run
```

## 设计要点

- **状态管理**：建议 `riverpod` —— provider 更现代且对异步好。
- **路由**：`go_router`，方便深链接（推送通知打开特定 Quest）。
- **网络**：`dio`，自动重试 + 拦截器加 `X-User-Id` header（v0 假认证）。
- **本地存储**：`shared_preferences` 存 token；不缓存 Quest 内容（每天都拉新的）。
- **推送**：Daily Quest 推送是核心 —— 见 PRD「习惯锚点」。早期用 firebase_messaging。

## 页面骨架

```
lib/
├── main.dart              入口 + Riverpod ProviderScope
├── screens/
│   ├── splash.dart        启动 → 检查 onboarding 状态
│   ├── onboarding.dart    诊断测试 10 题
│   ├── home.dart          Today's Quest + Streak
│   ├── quest.dart         单个 Quest 详情（解释 → quiz → practice）
│   ├── tutor.dart         Tutor Chat
│   └── memory.dart        我的学习快照
├── services/
│   ├── api.dart           dio 客户端
│   ├── auth.dart          token + user_id 存取
│   └── quest_repo.dart    Quest API 调用
├── models/                响应 DTO
└── widgets/               复用组件（StreakBadge, QuizCard 等）
```

## 设计原则（来自 PRD）

1. **节奏感**：每日推送 + streak + 视觉反馈（断了不惩罚）。
2. **陪伴感**：Tutor 对话要有温度，不要"AI 助手"风格。
3. **深度感**：服务有认知的成人，不要幼稚化（拒绝过多 emoji 和儿童化插画）。
