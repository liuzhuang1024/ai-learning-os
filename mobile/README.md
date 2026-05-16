# Mobile (Flutter)

iOS + Android. Mobile-first because学习行为是高频碎片化的——见 PRD §产品形态。

## 启动

```bash
flutter pub get
# 后端在另一个终端先起好：
#   cd ../backend && uv run uvicorn app.main:app --reload
flutter run
```

要在真机/模拟器上指向局域网里的后端：

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000
```

## 现状

- ✅ 平台壳子（iOS + Android）已 bootstrap，`flutter analyze` 干净
- ✅ 5 个页面实现：Splash / Onboarding / Home / Quest / Tutor / Memory
- ✅ Riverpod + go_router + dio 串好
- ⚠️ 仍在用 v0 假认证：本机生成 uuid 存 shared_preferences，作为 X-User-Id 发送
- ⚠️ 没接推送通知（Daily Quest 提醒）

## 设计要点

- **状态管理**：riverpod
- **路由**：go_router
- **网络**：dio，base URL 通过 `--dart-define=API_BASE_URL=...` 注入
- **本地存储**：shared_preferences（user_id + onboarded flag）
- **设计语言**：sober Material 3，单一种子色 `#6B5BFF`，无 emoji、无儿童化插画

## 页面结构

```
lib/
├── main.dart              入口 + theme + ProviderScope
├── router.dart            go_router 配置
├── providers.dart         Auth / Api Riverpod providers
├── screens/
│   ├── splash.dart        启动 → 检查 onboarding 状态分流
│   ├── onboarding.dart    3 步：背景 → 风格 → 测试题
│   ├── home.dart          今日任务卡片 + 导师/记忆入口
│   ├── quest.dart         概念解释 → quiz → 动手环节
│   ├── tutor.dart         聊天 UI（带历史 + typing 指示器）
│   └── memory.dart        概念掌握列表 + 置信度条
├── services/
│   ├── api.dart           dio 客户端，封装所有 backend 调用
│   └── auth.dart          本地 uuid + onboarded flag
├── models/                响应 DTO（quest / assessment / memory / chat）
└── widgets/
    └── confidence_bar.dart
```
