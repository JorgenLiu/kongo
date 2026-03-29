# Outlook Calendar Sync V1 Implementation Plan

**Goal:** 通过 Microsoft Graph OAuth 接入 Outlook/Teams 日历，在不依赖 Kongo 服务器的前提下，把过去 14 天与未来 30 天的会议单向同步到本地 `events`，为后续会前准备与会后补充打基础。

**Architecture:** 采用本地优先、单向导入的设计。UI 只展示连接与同步状态；OAuth 与 token 刷新由独立认证服务负责；Graph HTTP 调用由独立客户端负责；同步编排层负责把远端事件 upsert 到本地 `events`，并通过独立映射表维护远端 ID 与本地事件的对应关系。

**Tech Stack:** sqflite, Dart `http`, `flutter_web_auth_2`, Flutter Material 3, `provider`

---

## File Map

**Create:**
- `lib/models/outlook_account.dart`
- `lib/models/outlook_calendar_event.dart`
- `lib/models/outlook_sync_result.dart`
- `lib/repositories/event_sync_source_repository.dart`
- `lib/services/outlook_auth_service.dart`
- `lib/services/outlook_graph_service.dart`
- `lib/services/outlook_calendar_sync_service.dart`
- `lib/providers/outlook_sync_provider.dart`
- `lib/widgets/settings/outlook_sync_section.dart`
- `test/services/outlook_auth_service_test.dart`
- `test/services/outlook_calendar_sync_service_test.dart`

**Modify:**
- `pubspec.yaml`
- `lib/services/database_service.dart`
- `lib/services/migrations/database_schema.dart`
- `lib/services/migrations/database_migrations.dart`
- `lib/services/settings_preferences_store.dart`
- `lib/repositories/event_repository.dart`
- `lib/services/app_dependencies.dart`
- `lib/main.dart`
- `lib/screens/settings/settings_overview_screen.dart`
- `doc/PRODUCT_STRATEGY_2026.md`（如实现过程中需要同步 v1 范围）

---

## Out of Scope

- Outlook 联系人同步（`Contacts.Read`）
- attendee 自动建联系人或自动关联现有联系人
- 双向同步（本地改动回写 Outlook）
- 后台定时同步 / 菜单栏常驻同步
- 系统安全存储（Keychain / Credential Manager）
- 复杂冲突合并与远端缺失即删除
- Outlook `description/body` 富文本导入

---

## Data Model

### 新增同步映射表

新增 `event_sync_sources` 表，用于维护本地 `events` 与远端 Graph 事件的映射关系。

建议字段：
- `id TEXT PRIMARY KEY`
- `eventId TEXT NOT NULL`
- `provider TEXT NOT NULL`
- `externalId TEXT NOT NULL`
- `externalCalendarId TEXT`
- `externalICalUId TEXT`
- `externalChangeKey TEXT`
- `externalLastModifiedAt INTEGER`
- `lastSyncedAt INTEGER NOT NULL`
- `createdAt INTEGER NOT NULL`
- `updatedAt INTEGER NOT NULL`

约束与索引：
- `FOREIGN KEY (eventId) REFERENCES events(id) ON DELETE CASCADE`
- `UNIQUE(provider, externalId)`
- 为 `eventId`、`provider`、`externalLastModifiedAt` 建索引

### 本地事件覆盖规则

远端允许覆盖：
- `title`
- `startAt`
- `endAt`
- `location`
- `status`

本地保留，不被远端覆盖：
- `description`
- 附件关系
- AI 输出
- 本地待办/行动项
- 本地补充的人脉关系沉淀

---

## Tasks

### Task 1: 增加依赖与 schema

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/services/database_service.dart`
- Modify: `lib/services/migrations/database_schema.dart`
- Modify: `lib/services/migrations/database_migrations.dart`

- [ ] 在 `pubspec.yaml` 新增 `flutter_web_auth_2` 依赖
- [ ] 将数据库版本从 `9` 升到 `10`
- [ ] 在 `database_schema.dart` 新增 `createEventSyncSourcesTable` 及相关索引
- [ ] 在 `createSchemaStatements` 中注册新表与索引
- [ ] 在 `database_migrations.dart` 中新增 `migrateToVersion10(Database db)`
- [ ] 在 `onUpgradeDatabase` 中挂接 `if (oldVersion < 10)` 分支
- [ ] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze lib/services/migrations/`

### Task 2: 建立同步映射 repository 与模型

**Files:**
- Create: `lib/models/outlook_account.dart`
- Create: `lib/models/outlook_calendar_event.dart`
- Create: `lib/models/outlook_sync_result.dart`
- Create: `lib/repositories/event_sync_source_repository.dart`

- [ ] 定义 `OutlookAccount`：邮箱、显示名、tenantId、scopes、expiresAt 等字段
- [ ] 定义 `OutlookCalendarEvent`：Graph 事件最小字段集（id、subject、start/end、location、changeKey、lastModifiedDateTime、isCancelled）
- [ ] 定义 `OutlookSyncResult`：新增数、更新数、失败数、同步时间、错误摘要
- [ ] 定义 `EventSyncSource` 模型与 `EventSyncSourceRepository`
- [ ] 实现 `SqliteEventSyncSourceRepository` 的查询、按 `(provider, externalId)` 查找、插入、更新能力
- [ ] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze lib/models/ lib/repositories/`

### Task 3: 实现 Outlook 认证服务

**Files:**
- Modify: `lib/services/settings_preferences_store.dart`
- Create: `lib/services/outlook_auth_service.dart`

- [ ] 基于现有 `SettingsPreferencesStore` 增加 token 存取所需的通用字符串能力（若当前实现已支持则复用）
- [ ] 实现 `OutlookAuthService`：
  - 登录（Authorization Code + PKCE）
  - code 换 token
  - refresh token 刷新
  - 读取当前账号状态
  - 断开连接清理 token
- [ ] v1 scope 固定为：`User.Read Calendars.Read offline_access`
- [ ] 回调采用自定义 URL Scheme（如 `kongo://auth/outlook`）
- [ ] 明确 token 先保存在本地 JSON settings store，后续再迁安全存储
- [ ] 新增测试：`test/services/outlook_auth_service_test.dart`
- [ ] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze lib/services/outlook_auth_service.dart test/services/outlook_auth_service_test.dart`

### Task 4: 实现 Graph 客户端与同步编排

**Files:**
- Create: `lib/services/outlook_graph_service.dart`
- Create: `lib/services/outlook_calendar_sync_service.dart`
- Modify: `lib/repositories/event_repository.dart`

- [ ] 实现 `OutlookGraphService`：
  - 获取当前用户 `/me`
  - 获取窗口事件 `/me/calendarView`
  - 把远端 JSON 转成 `OutlookCalendarEvent`
- [ ] 实现 `OutlookCalendarSyncService`：
  - 确保 token 可用
  - 拉取“过去 14 天 + 未来 30 天”时间窗事件
  - 逐条 upsert 到本地 `events`
  - 创建或更新 `event_sync_sources`
  - 对取消事件写入 `status = cancelled`
  - 对单条失败进行计数，不中断整批同步
- [ ] 在 `event_repository.dart` 复用现有插入/更新能力；必要时补一个面向同步场景的辅助方法，但不要引入 Outlook 专属逻辑到通用 repository 接口
- [ ] 忽略 Outlook `description/body`，v1 只同步会议骨架
- [ ] 新增测试：`test/services/outlook_calendar_sync_service_test.dart`
- [ ] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze lib/services/outlook_graph_service.dart lib/services/outlook_calendar_sync_service.dart test/services/outlook_calendar_sync_service_test.dart`

### Task 5: 连接设置页与 provider

**Files:**
- Create: `lib/providers/outlook_sync_provider.dart`
- Create: `lib/widgets/settings/outlook_sync_section.dart`
- Modify: `lib/services/app_dependencies.dart`
- Modify: `lib/main.dart`
- Modify: `lib/screens/settings/settings_overview_screen.dart`

- [ ] 实现 `OutlookSyncProvider`，暴露：
  - 已连接/未连接/连接失效状态
  - 同步中状态
  - 最近同步时间
  - `connect()` / `syncNow()` / `disconnect()`
- [ ] 在 `AppDependencies` 中注册：
  - `OutlookAuthService`
  - `OutlookGraphService`
  - `OutlookCalendarSyncService`
  - `OutlookSyncProvider`
- [ ] 在 `main.dart` 将 `OutlookSyncProvider` 注入 widget tree
- [ ] 新增 `OutlookSyncSection`，只负责：
  - 展示账号与同步状态
  - 触发连接
  - 触发立即同步
  - 触发断开连接
- [ ] 在 `settings_overview_screen.dart` 挂载 `OutlookSyncSection`
- [ ] 保持 screen 文件只做组合，不把 OAuth/HTTP 逻辑塞进 screen
- [ ] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze lib/providers/ lib/widgets/settings/ lib/screens/settings/`

### Task 6: 启动时自动同步（非阻塞）

**Files:**
- Modify: `lib/services/app_dependencies.dart`

- [ ] 在 `AppDependencies.bootstrap()` 中检测是否已有有效 Outlook 授权
- [ ] 若已授权，则异步触发一次 `syncWindow()`
- [ ] 确保同步不阻塞主 app 启动，不影响首页与其他 provider 初始化
- [ ] 如果同步失败，只记录状态，不让 app 启动失败
- [ ] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze lib/services/app_dependencies.dart`

### Task 7: 集成验证

- [ ] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter pub get`
- [ ] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze`
- [ ] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter test`
- [ ] 手动验证：
  - 设置页可看到 Outlook 区块
  - 点击“连接 Outlook”可进入授权流程
  - 授权后显示账号信息
  - 点击“立即同步”可把时间窗内会议导入本地
  - 重复同步不会产生重复事件
  - 取消的会议状态变为 `cancelled`

---

## Expected V1 Outcome

- 用户能在本机完成 Outlook 登录
- Kongo 能在启动时或手动触发时同步时间窗内会议
- 远端会议稳定导入本地 `events`
- 同一 Graph 事件不会重复创建本地事件
- 同步失败不会影响其他应用功能

---

## Notes

- v1 首要目标是验证 Outlook 接入是否能稳定为“会前准备 / 会后补充”提供骨架数据，不追求一次性覆盖联系人同步、双向回写和后台常驻同步。
- 如果实现过程中发现 `events.status` 运行时模型与数据库字段的边界会影响取消会议处理，应在同一任务中补一份最小兼容方案，而不是把取消逻辑强塞进 UI 层。