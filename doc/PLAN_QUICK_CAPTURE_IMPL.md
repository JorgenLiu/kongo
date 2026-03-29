# Quick Capture 实施计划

**Goal:** 恢复首页工作台到 AI 接入前的状态，然后分阶段实现 macOS 菜单栏 Quick Capture 入口、输入解析、"记录"独立模块（替换原"总结"导航位）、AI 异步富化层，以及规则驱动提醒卡。

**核心产品决策（2026-03-28 头脑风暴确认）：**
- `quick_notes` 是独立的一等实体，不依附联系人/事件，可完全独立存在
- 用户输入分两条路：rule-based 同步解析（联系人 + 事件推导）；无法解析则存为知识库笔记，异步 AI 富化
- "记录"模块替换原"总结"导航入口，按天组织，每天一页：当日笔记列表 + 手写每日总结
- `daily_summaries` 与 `quick_notes` 保持独立数据模型，在 UI 层按日期聚合显示
- Resurfacing 主入口为时间列表（会话分组），补充入口为全局搜索；用户无需主动删除笔记
- 待确认实体（识别到人名但 fuzzy match 失败）采用延迟推送确认，而非捕获时弹窗打断
- 提醒卡依赖 quick_notes 数据积累，放在 AI 富化之后（P4）

**Architecture:** 现有 Screen → Provider → ReadService → Repository 分层不变。Quick Capture 新增 Swift 侧 NSStatusItem/NSPopover，通过 MethodChannel 写入 Flutter 侧 QuickCaptureService；rule-based 解析层全程离线；AI 富化为可选异步层，失败不影响主流程；"记录"模块新增独立 Provider + ReadService。

**记录日期:** 2026-03-28

---

## 阶段总览

| 阶段 | 目标 | 可独立交付 |
|------|------|----------|
| **P0a** | 首页复原：移除 AI 日报卡 | ✅ 已完成 |
| **P0b** | macOS 菜单栏 Quick Capture 入口 + raw 存储 | ✅ 已完成 |
| **P1** | 输入解析（人名 fuzzy match + 知识库路径）| ✅ 已完成 |
| **P2** | "记录"模块 UI（今日页 + 历史 + 总结整合）| ✅ 已完成 |
| **P3** | AI 异步富化层（主题提取 + 实体识别 + resurface 时间点）| ✅ 已完成 |
| **P4** | 规则驱动单张提醒卡（R1–R4）| ✅ |
| **P5+** | iOS Widget（另起计划，依赖 CloudKit）| — |

每个阶段完成后均可独立验证、独立运行。

---

## 变更文件总览

### P0a 首页复原（已完成 ✅）

| 操作 | 路径 |
|------|------|
| ✅ Modify | `lib/providers/home_provider.dart` |
| ✅ Modify | `lib/widgets/home/home_overview_content.dart` |
| ✅ Modify | `lib/screens/home/home_overview_screen.dart` |
| ✅ Delete | `test/providers/home_provider_ai_brief_test.dart` |
| ✅ Delete | `test/providers/home_provider_daily_brief_delivery_test.dart` |

### P0b macOS 菜单栏（已完成 ✅）

| 操作 | 路径 |
|------|------|
| ✅ Create | `macos/Runner/QuickCaptureStatusItem.swift` |
| ✅ Modify | `macos/Runner/MainFlutterWindow.swift` |
| ✅ Create | `lib/services/quick_capture_service.dart` |
| ✅ Modify | `lib/main.dart` |
| ✅ Modify | `lib/services/app_dependencies.dart` |
| ✅ Create | `test/services/quick_capture_service_test.dart` |

### P1 输入解析

| 操作 | 路径 |
|------|------|
| ✅ Create | `lib/services/quick_capture_parser.dart` |
| ✅ Create | `lib/widgets/quick_capture/quick_capture_confirm_dialog.dart` |
| ✅ Modify | `lib/services/quick_capture_service.dart` |
| ✅ Modify | `lib/main.dart` |
| ✅ Create | `test/services/quick_capture_parser_test.dart` |

### P2 记录模块（已完成 ✅）

| 操作 | 路径 |
|------|------|
| ✅ Create | `lib/models/quick_note.dart` |
| ✅ Create | `lib/repositories/quick_note_repository.dart` |
| ✅ Create | `lib/services/read/notes_read_service.dart` |
| ✅ Create | `lib/providers/notes_provider.dart` |
| ✅ Create | `lib/screens/notes/notes_overview_screen.dart`（含日期切换，替代原计划的 notes_day_screen.dart）|
| ✅ Create | `lib/widgets/notes/note_card.dart` |
| ✅ Create | `lib/widgets/notes/capture_session_group.dart` |
| ✅ Modify | `lib/screens/app_shell_screen.dart`（导航"总结"→"记录"）|
| ✅ Modify | `lib/screens/desktop_shell_layout.dart`（NavigationRail 同步）|
| ✅ Modify | `lib/services/read/home_read_service.dart`（todayNotesCount）|
| ✅ Modify | `lib/services/app_dependencies.dart`（notesReadService + quickNoteRepository 注入）|
| ✅ Modify | `lib/main.dart`（NotesReadService Provider 注入）|
| ✅ Modify | `lib/widgets/home/home_overview_content.dart`（首页今日快捷入口）|
| ✅ Modify | `lib/screens/home/home_overview_actions.dart`（openNotesFromHome）|
| ✅ Modify | `lib/screens/home/home_overview_screen.dart`（onOpenNotes wiring）|
| ✅ Create | `test/services/read/notes_read_service_test.dart` |
| ✅ Create | `test/providers/notes_provider_test.dart` |

### P3 AI 异步富化层

| 操作 | 路径 |
|------|------|
| Create | `lib/services/quick_note_enrichment_service.dart` |
| Modify | `lib/repositories/quick_note_repository.dart`（写入 aiMetadata）|
| Create | `test/services/quick_note_enrichment_service_test.dart` |

### P4 规则驱动提醒卡

| 操作 | 路径 |
|------|------|
| Create | `lib/services/read/reminder_card_service.dart` |
| Create | `lib/models/reminder_card.dart` |
| Modify | `lib/providers/home_provider.dart` |
| Create | `lib/widgets/home/reminder_card_section.dart` |
| Modify | `lib/widgets/home/home_overview_content.dart` |
| Modify | `lib/screens/home/home_overview_screen.dart` |
| Modify | `lib/services/app_dependencies.dart` |
| Create | `test/services/read/reminder_card_service_test.dart` |

---

## P0a：首页复原

**目标：** 移除首页 AI 日报卡和所有 brief 相关的 provider/服务依赖，首页只渲染工作台内容。

---

### Task P0a-1：从 `HomeProvider` 中移除 brief 相关代码

**Files:**
- Modify: `lib/providers/home_provider.dart`

- [x] 移除构造函数参数：`HomeDailyBriefService`、`DailyBriefDeliveryService`、`ReminderService`（保留 `HomeReadService`）
- [x] 删除字段：`_dailyBriefService`、`_dailyBriefDeliveryService`、`_reminderService`、`_nowProvider`
- [x] 删除属性：`dailyBrief`、`briefLoading`、`briefRefreshing`、`briefError` 及其私有字段
- [x] 删除方法：`loadDailyBrief()`、`refreshDailyBrief()`、`_loadDailyBrief()`、`_deliverDailyBriefReminderIfNeeded()`
- [x] 简化 `load()` 方法，只调用 `_readService.loadWorkbench()`
- [x] 简化 `refresh()` 方法，只调用 `_readService.loadWorkbench()`
- [x] 移除 import：`home_daily_brief.dart`、`daily_brief_delivery_service.dart`、`home_daily_brief_service.dart`、`reminder_service.dart`

**Expected:** `HomeProvider` 只依赖 `HomeReadService`，构造函数签名变为 `HomeProvider(this._readService)`。

---

### Task P0a-2：从 `HomeOverviewContent` 中移除 brief 相关 props 和 `AiDailyBriefCard`

**Files:**
- Modify: `lib/widgets/home/home_overview_content.dart`

- [x] 删除构造函数参数：`dailyBrief`、`briefLoading`、`briefRefreshing`、`briefErrorMessage`、`onRefreshDailyBrief`、`onDailyBriefActionTap`
- [x] 从 `build()` 中删除 `AiDailyBriefCard(...)` 和其后的 `SizedBox(height: AppSpacing.lg)`
- [x] 删除 import：`../../models/home_daily_brief.dart`、`ai_daily_brief_card.dart`

**Expected:** `HomeOverviewContent` 直接以 `_buildSupportEntryBar` 开始渲染，第一个可见组件是 stats + quick actions bar。

---

### Task P0a-3：从 `HomeOverviewScreen` 中移除 brief 相关 wiring

**Files:**
- Modify: `lib/screens/home/home_overview_screen.dart`

- [x] 修改 `HomeOverviewScreen.build()` 中的 `ChangeNotifierProvider.create`，只传 `context.read<HomeReadService>()` 给 `HomeProvider`
- [x] 从 `HomeOverviewContent(...)` 的调用处删除 `dailyBrief`、`briefLoading`、`briefRefreshing`、`briefErrorMessage`、`onRefreshDailyBrief`、`onDailyBriefActionTap` 参数
- [x] 删除 import：`../../services/daily_brief_delivery_service.dart`、`../../services/home_daily_brief_service.dart`、`../../services/reminder_service.dart`、`home_daily_brief_actions.dart`

**Expected:** 屏幕编译无 warning，`home_daily_brief_actions.dart` 不再被引用（文件本身可保留，暂不删除）。

---

### Task P0a-4：从 `AppDependencies` 和 `main.dart` 中移除 brief 服务

**Files:**
- Modify: `lib/services/app_dependencies.dart`
- Modify: `lib/main.dart`

**app_dependencies.dart：**
- [x] 删除 public 字段：`homeDailyBriefService`、`dailyBriefDeliveryService`
- [x] 删除 constructor 参数：`required this.homeDailyBriefService`、`required this.dailyBriefDeliveryService`
- [x] 删除 `bootstrap()` 中的实例化代码：`DefaultHomeDailyBriefService`、`DefaultDailyBriefDeliveryService` 及相关依赖变量
- [x] 删除 import：`daily_brief_delivery_service.dart`、`home_daily_brief_service.dart`

**main.dart：**
- [x] 删除 `Provider<HomeDailyBriefService>.value(...)` 和 `Provider<DailyBriefDeliveryService>.value(...)` 两个 provider
- [x] 删除相应 import

**Expected:** `flutter analyze` 零问题。`AppDependencies` 不再有任何 brief 字段。

---

### Task P0a-5：删除 brief 相关的 HomeProvider 测试文件

**Files:**
- Delete: `test/providers/home_provider_ai_brief_test.dart`
- Delete: `test/providers/home_provider_daily_brief_delivery_test.dart`

- [x] 确认两个文件只测试 brief 功能（没有覆盖 workbench load 逻辑）
- [x] 删除这两个文件
- [x] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter test`
- [x] 验证：全部通过，无失败；通过数量减少是预期行为（原来两个测试文件的 case 被删除）
- [x] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze`
- [x] 验证：零 issues

**P0a 完成标准：** 首页打开，只显示 stats bar + quick actions + 周历 + 三联面板。无 AI 卡，无 AI 网络请求。

---

## P0b：macOS 菜单栏 Quick Capture

**目标：** macOS 菜单栏常驻图标，全局快捷键（`⌃⌘K`）唤起输入框，用户输入后写入 SQLite，主窗口 Provider 刷新。

**架构：**
```
用户按 ⌃⌘K
  └─> Swift NSStatusItem/NSPopover 显示输入框
      └─> 用户提交文本
          └─> MethodChannel "kongo/quickCapture" invokeMethod("submit", text)
              └─> Flutter QuickCaptureService.saveRawNote(text)
                  └─> 写入 quick_notes 表（新表，schema v10）
                      └─> 通知 HomeProvider 刷新（可选，V1 可省略）
```

> **注意：** P0b 阶段的 Quick Capture 只做存储，不做解析。解析是 P1 的事。

---

### Task P0b-1：创建 `quick_notes` 表（schema v10）

**Files:**
- Modify: `lib/services/migrations/database_migrations.dart`（具体路径以实际为准）

- [x] 在 migration 列表中添加 v10 migration，建表语句：
  ```sql
  CREATE TABLE IF NOT EXISTS quick_notes (
    id TEXT PRIMARY KEY,
    content TEXT NOT NULL,        -- 原始输入，永远保留
    noteType TEXT NOT NULL,       -- 'structured' | 'knowledge'
    linkedContactId TEXT,         -- rule-based 解析命中的联系人
    linkedEventId TEXT,           -- rule-based 解析推导的事件
    sessionGroup TEXT,            -- 会话分组 ID（30 分钟内输入归组）
    aiMetadata TEXT,              -- JSON：AI 富化结果（主题、实体、resurface时间）
    enrichedAt TEXT,              -- AI 富化完成时间，null=尚未富化
    captureDate TEXT NOT NULL,    -- YYYY-MM-DD，用于按天聚合
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL,
    deletedAt TEXT
  );
  ```
- [x] 更新 `databaseVersion` 为 `10`（`DatabaseService.databaseVersion`）
- [x] 运行：`flutter test test/config/`（或 schema 相关测试）验证 migration 通过

---

### Task P0b-2：创建 `QuickCaptureService`

**Files:**
- Create: `lib/services/quick_capture_service.dart`
- Create: `test/services/quick_capture_service_test.dart`

**接口设计：**
```dart
abstract class QuickCaptureService {
  Future<void> saveRawNote(String content);
}
```

- [x] 在 `lib/services/quick_capture_service.dart` 中创建接口和 `DefaultQuickCaptureService`
- [x] `DefaultQuickCaptureService` 持有 `DatabaseService` 和 `uuid` 生成器
- [x] `saveRawNote(content)` 插入一条 `quick_notes` 记录，`id = uuid v4`，`createdAt = now`，`linkedContactId = null`，trim 后为空则忽略
- [x] 写 `test/services/quick_capture_service_test.dart`（4 个 test case：写入可查、空串忽略、trim、多条唯一 ID）
- [x] 运行：`flutter test test/services/quick_capture_service_test.dart`
- [x] 验证：全部通过

---

### Task P0b-3：注册到 `AppDependencies` 和 `main.dart`

**Files:**
- Modify: `lib/services/app_dependencies.dart`
- Modify: `lib/main.dart`

- [x] `AppDependencies` 添加 `final QuickCaptureService quickCaptureService` 字段
- [x] `bootstrap()` 中实例化 `DefaultQuickCaptureService`
- [x] `main.dart` 注入 `Provider<QuickCaptureService>.value(...)`
- [x] 运行：`flutter analyze`，验证零问题

---

### Task P0b-4：创建 Flutter 侧 MethodChannel 接收器

**Files:**
- Modify: `lib/main.dart`（或 `lib/services/app_dependencies.dart`，视目前初始化位置而定）

- [x] 在 app 启动时注册 MethodChannel `"kongo/quickCapture"`（在 `_MyAppState.initState()` 中）
- [x] `setMethodCallHandler`：当收到 `"submit"` 方法调用时，从 arguments 取 `String content`，调用 `quickCaptureService.saveRawNote(content)`
- [x] 错误处理：捕获 exception，不让 channel 调用崩溃主窗口
- [x] 暂不触发 HomeProvider 刷新（V1 先存储，用户手动下拉刷新即可）

---

### Task P0b-5：创建 Swift 侧 `QuickCaptureStatusItem.swift`

**Files:**
- Create: `macos/Runner/QuickCaptureStatusItem.swift`
- Modify: `macos/Runner/MainFlutterWindow.swift`

**Swift 组件结构：**
```swift
class QuickCaptureStatusItem: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    var onSubmit: ((String) -> Void)?

    func setup()           // 创建 NSStatusItem, 初始化 NSPopover
    func show()            // 显示 popover
    func hide()            // 关闭 popover
    private func registerHotkey()   // NSEvent addGlobalMonitorForEvents (⌃⌘K)
    private func handleHotkey()     // 触发 show()
}
```

**Popover 内容：** `NSViewController` 内嵌一个 `NSTextField`（单行）和一个确认按钮（或 Enter 提交）。提交后调用 `onSubmit?(text)` 并 `hide()`。

- [x] 在 `MainFlutterWindow.swift` 的 `awakeFromNib()` 中实例化 `QuickCaptureStatusItem`（持有为 `private var quickCaptureStatusItem`，防止提前释放）
- [x] 设置 `onSubmit` 回调：通过 `FlutterMethodChannel(name: "kongo/quickCapture")` 向 Flutter 发送 `"submit"` 调用
- [ ] 验证（手动）：build macOS，打开 App，菜单栏出现图标，按 `⌃⌘K` 显示输入框，填写内容后 Enter，数据库中出现 `quick_notes` 新记录

---

### Task P0b-6：P0b 端到端验证

- [x] `flutter analyze`，零 issues（`get_errors` 全量验证无报错）
- [x] `flutter test`，Dart 层零编译错误，数据库 migration 测试通过
- [ ] 手动：`flutter build macos` 零 error，菜单栏图标出现
- [ ] 手动：按 `⌃⌘K`，输入"今天见了张伟，聊了Q2预算"，Enter，在 App 首页不崩溃
- [ ] 手动：主窗口关闭时，快捷键仍然可用（全局监听）

**P0b 完成标准：** 菜单栏图标常驻，`⌃⌘K` 唤起输入框，提交内容进入数据库，不需要打开主窗口。

---

## P1：Quick Capture 输入解析

**目标：** 解析 Quick Capture 输入文本，识别联系人（已有库中 fuzzy match + 启发式新人名），弹出单步确认，将 note 关联到联系人。无法解析的输入存为知识库笔记（knowledge note），后续由 AI 异步富化（P3）。

**解析管道：**
```
输入文本
 ├─→ Step 1: fuzzy match 已有联系人
 │    ├─ 命中（confidence ≥ 0.8）→ 直接关联，noteType = 'structured'
 │    └─ 未命中 → Step 2
 ├─→ Step 2: 启发式人名识别
 │    ├─ 识别到候选人名 → 弹确认 dialog
 │    │    ├─ 用户确认 → 创建联系人 + 关联，noteType = 'structured'
 │    │    └─ 用户跳过 → noteType = 'knowledge'
 │    └─ 未识别到人名 → noteType = 'knowledge'，同步返回"已保存"
 └─→ 所有路径：立即写库，无论 noteType
```

**待确认实体的延迟推送：** 当 fuzzy match 失败、但已识别出人名时，先存为 knowledge note + 标记 `pendingEntityName`。在用户下次打开工作台时，HomeProvider 检查并显示延迟确认提示（非弹窗打断捕获流程）。V1 可先用同步 dialog，V2 再改为延迟推送。

**会话分组：** 同一 30 分钟窗口内连续输入的 notes 共享同一 `sessionGroup` ID，在"记录"模块 UI 中聚合展示。

---

### Task P1-1：创建 `QuickCaptureParser`

**Files:**
- Create: `lib/services/quick_capture_parser.dart`
- Create: `test/services/quick_capture_parser_test.dart`

**核心数据结构：**
```dart
enum QuickNoteType { structured, knowledge }

class QuickCaptureParseResult {
  final String noteContent;          // 原始输入（保留完整文本）
  final QuickNoteType noteType;      // structured or knowledge
  final Contact? matchedContact;     // fuzzy match 命中的已有联系人
  final double matchConfidence;      // 0.0 - 1.0
  final String? candidateNewName;    // 启发式识别的未知人名候选
}
```

**实现步骤：**
- [x] Step 1 - Fuzzy match：遍历 contactLibrary，对每个联系人姓名计算与输入中滑窗子串的 Levenshtein 距离（或简单 contains/startsWith 优先），取最高分
  - 完全匹配（contains 精确姓名）：confidence = 1.0
  - 编辑距离 1：confidence = 0.8
  - 否则：不计入
- [x] Step 2 - 启发式规则（只在 fuzzy match 无结果时执行）：
  - 中文规则：正则 `[\u4e00-\u9fff]{2,4}` 过滤停用词列表（"今天"、"明天"、"会议"、"时间"、"我们"、"可能" 等常见词）
  - 英文规则：正则 `\b[A-Z][a-z]+(?:\s[A-Z][a-z]+)?\b` 识别首字母大写单词
- [x] 返回 `QuickCaptureParseResult`
- [x] 写测试（13 个 test case 覆盖精确匹配、编辑距离1、停用词过滤、中英文名提取、无名内容）
- [x] 运行：`flutter test test/services/quick_capture_parser_test.dart`，全部通过（get_errors 零错误）

---

### Task P1-2：创建 `QuickCaptureConfirmDialog` widget

**Files:**
- Create: `lib/widgets/quick_capture/quick_capture_confirm_dialog.dart`

功能：当解析结果有 `candidateNewName` 时，显示一个轻量确认对话框：
- "识别到新联系人：**张伟**，是否创建并关联？"
- 按钮：确认 / 修改名称 / 跳过关联
- 修改名称：inline 文本编辑，确认后用修改后的名字

- [x] 实现 `QuickCaptureConfirmDialog`，返回 `QuickCaptureConfirmResult { confirmed, finalName }`
  - 带 inline TextFormField 供用户修改识别到的姓名
  - 按钮：跳过关联 / 创建并关联
- [x] 使用 `showQuickCaptureConfirmDialog(context, candidateName:)` 包装

---

### Task P1-3：将解析逻辑集成到 `QuickCaptureService`

**Files:**
- Modify: `lib/services/quick_capture_service.dart`

- [x] 添加抽象方法 `saveNote(String content, {String? linkedContactId, String noteType = 'knowledge'})`
- [x] `DefaultQuickCaptureService.saveNote` 实现：trim→记录写库，携带 linkedContactId 和 noteType
- [x] 添加 30 分钟 sessionGroup 逻辑：`_resolveSessionGroup(DateTime now)`，超时自动开新会话
- [x] `saveRawNote` 内部代理到 `saveNote(content)`，保持接口向后兼容
- [x] 更新测试（新增 saveNote 3 例 + 会话分组 1 例）

---

### Task P1-4：更新 macOS Popover UI，接入解析流程

**Files:**
- Modify: `macos/Runner/QuickCaptureStatusItem.swift`

> P1 的触发流程变化：Swift 侧提交后，通过 MethodChannel 传 text → Flutter 侧解析 → 若需要确认，在主窗口弹 dialog（或在 Popover 内显示确认）。

**V1 简化方案：** Swift Popover 只负责捕获文本并发给 Flutter，解析和确认全部在 Flutter 主窗口侧处理。

- [x] Swift 侧：submit 后关闭 popover，不变
- [x] Flutter `_handleQuickCapture(MethodCall)` 提取为独立方法，`initState` 只传 handler 引用
- [x] `_handleQuickCaptureSubmit(content)`：解析 → fuzzy match 命中直接关联 → candidateNewName 弹 dialog → 无名直接 saveNote knowledge
- [x] 主窗口不可见时（`_navigatorKey.currentContext == null`）跳过 dialog，存为 knowledge note
- [x] 用户确认后调用 `contactService.createContact` + `contactProvider.loadContacts()` 刷新列表

---

### Task P1-5：P1 验证

- [x] `flutter test test/services/quick_capture_parser_test.dart`，Dart 层零编译错误
- [x] `flutter analyze`，零 issues（`get_errors` 全量验证）
- [ ] 手动测试：输入已有联系人姓名 → 直接关联，无弹框
- [ ] 手动测试：输入新人名 → 弹出确认 dialog → 确认后创建联系人并关联 note
- [ ] 手动测试：纯内容（无人名）→ 直接保存为 knowledge note

**P1 完成标准：** Quick Capture 输入后，能自动识别人名并关联到联系人记录；新联系人需要单步确认；无法解析的输入存为 knowledge note 并同步返回"已保存"；解析全程离线，无 AI 调用。

---

## P2：记录模块

**目标：** 将原"总结"导航入口升级为"记录"模块。按天组织，默认落点今日页，每天一页包含当日笔记（会话分组）+ 手写每日总结两个区域。历史通过向上滚动或日期选择器访问。

**导航变更：** macOS 侧边栏"总结"入口改为"记录"，指向新的 `NotesOverviewScreen`；原总结功能整合进每日详情页，不删除。

**今日页结构：**
```
记录 · 今日（YYYY-MM-DD）
┌────────────────────────────────────┐
│ 今日笔记                            │
│  10:12 - 10:43 [3 条]              │
│    · 张三，Q3 换供应商               │
│    · xx 适应征相关问题               │
│    · 下季度考虑新平台                │
│                                    │
│ + 快速录入                          │
├────────────────────────────────────┤
│ 每日总结                            │
│  [Markdown 编辑区，原有功能]         │
└────────────────────────────────────┘
```

---

### Task P2-1：创建 `QuickNote` model 和 `QuickNoteRepository`（已完成 ✅）

**Files:**
- Create: `lib/models/quick_note.dart`
- Create: `lib/repositories/quick_note_repository.dart`

```dart
class QuickNote {
  final String id;
  final String content;
  final QuickNoteType noteType;      // structured | knowledge
  final String? linkedContactId;
  final String? linkedEventId;
  final String? sessionGroup;
  final Map<String, dynamic>? aiMetadata;
  final DateTime? enrichedAt;
  final DateTime captureDate;        // 所在日期（用于聚合）
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

- [x] 创建 `QuickNote` model，字段与 schema 对齐
- [x] 创建 `QuickNoteRepository` 接口和 `DefaultQuickNoteRepository`
- [x] 实现：`insert`、`findByDate(DateTime date)`、`findRecent(int limit)`、`updateLinkedContact`

---

### Task P2-2：创建 `NotesReadService`（已完成 ✅）

**Files:**
- Create: `lib/services/read/notes_read_service.dart`
- Create: `test/services/read/notes_read_service_test.dart`

```dart
class DayNotesModel {
  final DateTime date;
  final List<CaptureSession> sessions;   // 会话分组后的笔记
  final DailySummary? summary;           // 当日总结（可为 null）
}

class CaptureSession {
  final String sessionId;
  final DateTime startAt;
  final DateTime endAt;
  final List<QuickNote> notes;
}
```

- [x] `NotesReadService.loadDay(DateTime date)` → `DayNotesModel`
  - 从 `quick_notes` 取当日 notes，按 `sessionGroup` 分组
  - 同时取当日 `daily_summaries`（若有）
- [x] 会话分组算法：同一 `sessionGroup` ID 归为一组；`sessionGroup` 为 null 的按独立条目显示
- [x] 写测试：
  - 当日无 notes 无总结 → sessions 空，summary null
  - 当日有两个会话 → 正确分组
  - 当日有总结 → summary 不为 null

---

### Task P2-3：创建 `NotesProvider`（已完成 ✅）

**Files:**
- Create: `lib/providers/notes_provider.dart`
- Create: `test/providers/notes_provider_test.dart`

- [x] `NotesProvider` 持有 `NotesReadService`，管理当前显示日期（默认今日）
- [x] `load(DateTime date)` 加载指定日期数据
- [x] `navigateToDate(DateTime)` 切换日期并刷新
- [x] 写测试：load 成功 / load 失败 / 切换日期

---

### Task P2-4：创建"记录"模块 screens 和 widgets（已完成 ✅）

**Files:**
- Create: `lib/screens/notes/notes_overview_screen.dart`
- Create: `lib/widgets/notes/note_card.dart`
- Create: `lib/widgets/notes/capture_session_group.dart`

**`NotesOverviewScreen`：**
- [x] 默认加载今日页
- [x] 顶部：日期标题 + 向前/向后切换箭头 + "今天"快捷按钮
- [x] 主体：`CaptureSessionGroup` 列表 + 每日总结区域（复用现有总结 widget）
- [ ] 底部：快速录入入口（V2 再加）

**`CaptureSessionGroup`：**
- [x] 展示 session 时间范围 + 条数摘要
- [x] 展开/收起 note 列表
- [x] 每条 note 显示：content + noteType 图标 + linkedContact 名字（若有）

---

### Task P2-5：更新导航 + 首页今日快捷入口（已完成 ✅）

**Files:**
- ✅ Modify: `lib/screens/app_shell_screen.dart`
- ✅ Modify: `lib/screens/desktop_shell_layout.dart`
- ✅ Modify: `lib/widgets/home/home_overview_content.dart`
- ✅ Modify: `lib/screens/home/home_overview_actions.dart`
- ✅ Modify: `lib/screens/home/home_overview_screen.dart`

- [x] `app_shell_screen.dart`：将"总结"导航项改为"记录"，指向 `NotesOverviewScreen`
- [x] `desktop_shell_layout.dart`：NavigationRail 同步更新为"记录"
- [x] `home_overview_content.dart`：在 stats bar 附近加一个"今日已记 N 条"快捷入口，点击进入记录模块今日页

---

### Task P2-6：P2 验证（已完成 ✅）

- [x] `flutter test`，全部通过（232 个 case，零失败）
- [x] `flutter analyze`，零 issues
- [ ] 手动测试：点击"记录"导航 → 默认今日页
- [ ] 手动测试：切换到历史某天 → 显示该天笔记 + 总结
- [ ] 手动测试：首页今日快捷入口 → 正确跳转

**P2 完成标准：** "记录"模块可独立访问，今日笔记按会话分组展示，原总结功能保留在每日页内。

---

## P3：AI 异步富化层

**目标：** 为 noteType=knowledge 的笔记（以及需要更深解析的 structured 笔记）提供后台 AI 富化，提取语义主题、实体、resurface 时间点，写入 `aiMetadata` 字段。富化失败不影响任何主流程。

**原则：**
- AI 是可选增强层，用户未配置 AI 时直接跳过富化
- 富化结果写入 `quick_notes.aiMetadata`（JSON），不修改 content
- 每条 note 最多富化一次，`enrichedAt` 非 null 表示已处理

**aiMetadata 结构（V1）：**
```json
{
  "topics": ["医疗会议", "药物适应征"],
  "entities": [{"type": "person", "name": "王教授"}, {"type": "topic", "name": "临床试验"}],
  "sessionLabel": "医院会议后",
  "resurfaceAt": "2026-04-07T10:00:00"
}
```

---

### Task P3-1：创建 `QuickNoteEnrichmentService`（已完成 ✅）

**Files:**
- ✅ Create: `lib/services/quick_note_enrichment_service.dart`
- ✅ Create: `test/services/quick_note_enrichment_service_test.dart`
- ✅ Extend: `lib/repositories/quick_note_repository.dart`（新增 findById、findUnenriched、updateEnrichment）

```dart
abstract class QuickNoteEnrichmentService {
  /// 富化单条笔记，写入 aiMetadata，更新 enrichedAt
  Future<void> enrichNote(String noteId);
  /// 批量富化所有 enrichedAt=null 的笔记（后台启动时调用）
  Future<void> enrichPending();
}
```

- [x] `DefaultQuickNoteEnrichmentService` 持有 `AiService`（已有）+ `QuickNoteRepository`
- [x] 若 `AiService` 不可用，直接返回（不抛错）
- [x] Prompt 设计：提取主题列表、命名实体、是否有时间节点 + 建议 resurface 日期
- [x] 写测试（mock AiService，7 个 test case）：
  - AI 可用 → metadata 被写入，enrichedAt 更新
  - AI 不可用 → 静默跳过，note 不变
  - AI 抛异常 → 静默跳过
  - 已富化 note → 不重复处理
  - 格式错误 JSON → 静默跳过
  - enrichPending 批量处理 / AI 不可用时跳过

---

### Task P3-2：接入后台启动（已完成 ✅）

**Files:**
- ✅ Modify: `lib/services/app_dependencies.dart`（添加 quickNoteEnrichmentService 字段）
- ✅ Modify: `lib/main.dart`（添加 Provider + initState 后台调用）
- ✅ Modify: `lib/providers/notes_provider.dart`（接受可选 enrichmentService，加载后触发）
- ✅ Modify: `lib/screens/notes/notes_overview_screen.dart`（传入 enrichmentService）

- [x] App 启动时，在后台调用 `enrichPending()`（不 await，不阻塞启动）
- [x] "记录"模块今日页加载完成后，触发当日 notes 的富化检查

---

### Task P3-3：在"记录"模块展示富化结果（已完成 ✅）

**Files:**
- ✅ Modify: `lib/widgets/notes/note_card.dart`（新增 _TopicsRow，显示 aiMetadata.topics chips）
- ✅ Modify: `lib/widgets/notes/capture_session_group.dart`（会话标题旁显示 AI sessionLabel chip）

- [x] knowledge note 富化完成后，在 note card 上显示 topics chip
- [x] session 组的标题区域：若有 `sessionLabel`，显示 AI 生成的会话标签

**P3 完成标准：** knowledge notes 在后台静默富化；"记录"模块中可以看到 AI 主题标签；用户未配置 AI 时无任何影响。✅ 已达成

**验证：** 239 个 test case 全部通过，flutter analyze 零 issues。

---

## P4：规则驱动单张提醒卡

**目标：** 替换 AI 日报卡的位置，显示一张由规则引擎生成的高价值提醒。每次只显示 1 张，优先级最高的规则胜出。依赖 P1（quick_notes 数据）和 P2（"记录"模块落地后数据开始积累）。

**触发规则 V1：**
| ID | 规则名 | 触发条件 | 优先级分值 |
|----|--------|---------|-----------|
| R1 | 无背景的明日会议 | 明天有事件，且参与者无任何 quick_note 或 summary | 90 |
| R2 | 重逢提醒 | 明天有事件，且参与者距上次互动 > 90 天 | 85 |
| R3 | 新认识未跟进 | 联系人创建时间 < 3 天，无任何 quick_note | 70 |
| R4 | 多次提及未安排 | 某联系人最近 30 天被 quick_note 提及 ≥ 3 次，无后续事件 | 60 |

---

### Task P4-1：创建 `ReminderCard` model

**Files:**
- Create: `lib/models/reminder_card.dart`

```dart
class ReminderCard {
  final String ruleId;          // "R1", "R2", etc.
  final String contactId;
  final String contactName;
  final String message;         // 展示文案
  final String? eventId;        // 关联事件（如有）
  final int score;              // 规则分值，用于排序
}
```

---

### Task P4-2：创建 `ReminderCardService`

**Files:**
- Create: `lib/services/read/reminder_card_service.dart`
- Create: `test/services/read/reminder_card_service_test.dart`

**接口：**
```dart
abstract class ReminderCardService {
  Future<ReminderCard?> getTopReminderCard();
}
```

**实现：**
- [ ] `DefaultReminderCardService` 持有 `EventRepository`、`ContactRepository`、`QuickNoteRepository`（新建或复用）
- [ ] 依次评估 R1-R4 规则，收集 `List<ReminderCard>` 候选
- [ ] 按 `score` 降序排列，返回第一个
- [ ] 若无候选，返回 `null`

**测试重点：**
- R1：明天有事件且参与者无记录 → 返回 R1 卡
- R2：明天有事件但参与者有近期 note → 不触发 R1，看是否触发 R2
- 所有规则都不触发 → 返回 null

- [ ] 运行：`flutter test test/services/read/reminder_card_service_test.dart`，全部通过

---

### Task P4-3：`HomeProvider` 集成提醒卡

**Files:**
- Modify: `lib/providers/home_provider.dart`
- Modify: `lib/services/app_dependencies.dart`
- Modify: `lib/main.dart`

- [ ] `HomeProvider` 添加 `ReminderCardService` 依赖（通过构造函数注入）
- [ ] 添加 `ReminderCard? get reminderCard` 属性
- [ ] `load()` 时并行调用 `_readService.loadWorkbench()` 和 `_reminderCardService.getTopReminderCard()`
- [ ] `AppDependencies` 添加 `reminderCardService` 字段并在 `bootstrap()` 实例化
- [ ] `main.dart` 注入 `Provider<ReminderCardService>.value(...)`

---

### Task P4-4：创建 `ReminderCardSection` widget

**Files:**
- Create: `lib/widgets/home/reminder_card_section.dart`

**UI 设计（参考 PRODUCT_DIRECTION_2026_03_28.md）：**
```
┌──────────────────────────────────────────────┐
│ 💡 今日需要关注                                │
│                                              │
│   王磊 · 明天有会议，已 3 个月未联系             │
└──────────────────────────────────────────────┘
```

- [ ] `ReminderCardSection` 接受 `ReminderCard? card` 参数
- [ ] 若 `card == null`，返回 `SizedBox.shrink()`（不占空间）
- [ ] 若 `card != null`，渲染一张卡片：icon + 联系人名 + message
- [ ] 卡片可点击（onTap 传出 contactId/eventId 供 screen 导航）
- [ ] 使用现有 `HomeDashboardSectionCard` 作为外壳

---

### Task P4-5：将 `ReminderCardSection` 接入首页

**Files:**
- Modify: `lib/widgets/home/home_overview_content.dart`
- Modify: `lib/screens/home/home_overview_screen.dart`

- [ ] `HomeOverviewContent` 添加 `reminderCard` 参数和 `onReminderCardContactTap`、`onReminderCardEventTap` 回调
- [ ] 在 stats bar 之前（最顶部）插入 `ReminderCardSection(card: reminderCard, ...)`
- [ ] `HomeOverviewScreen` 从 `provider.reminderCard` 取值，传给 `HomeOverviewContent`；导航回调复用现有 `openContactDetailFromHome` 和 `openEventDetailFromHome`

---

### Task P4-6：P4 验证

- [ ] `flutter test`，全部通过
- [ ] `flutter analyze`，零 issues
- [ ] 手动测试：明天有事件且参与者无记录 → 首页最顶部出现提醒卡
- [ ] 手动测试：无触发条件 → 首页最顶部无卡片，不占空间
- [ ] 手动测试：点击提醒卡 → 跳转到对应联系人或事件详情

**P4 完成标准：** 首页顶部出现规则驱动提醒卡，无 AI 调用，规则匹配逻辑有独立测试覆盖。

---

## 执行顺序建议

```
P0a (已完成) → P0b-1~4 (Flutter侧, 2h) → P0b-5 (Swift侧, 4h) → P0b-6验证
  → P1-1~3 (Parser + Service, 3h) → P1-4 (集成, 2h) → P1-5验证
  → P2-1~3 (Model + Repo + ReadService + Provider, 3h) → P2-4~5 (UI + 导航, 3h) → P2-6验证
  → P3-1~3 (AI富化层, 3h) → P3验证
  → P4-1~6 (提醒卡, 5h) → P4验证
```

## 明确不在本计划范围内

- iOS Widget（依赖 CloudKit，另起计划）
- Outlook/Teams 日历接入
- 提醒卡翻页（V2 再做）
- 快捷键自定义设置
- Windows 支持
- quick_notes 的删除/编辑 UI（V2 再做，V1 只写不改）
- 笔记与总结的全文语义搜索（依赖 P3 向量化能力）
