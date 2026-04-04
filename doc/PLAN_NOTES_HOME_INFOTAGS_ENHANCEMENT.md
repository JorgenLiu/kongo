# Notes 增强 / 首页 QC 反馈 / Info Tags 激活 实施计划

**目标：**
1. Notes 模块支持跨日期浏览、联系人/事件维度筛选，与联系人详情双向穿透
2. 首页新增今日 Quick Capture 统计摘要卡，不影响现有布局
3. Info tags 接入全局搜索；联系人详情展示 tag 来源的原始 note 条目

**架构约束：**
- 严格遵循 Screen → Provider → ReadService → Repository 分层
- 不改动任何已闭环模块的主流程；扩展只在已有 provider/service 上追加方法或新增独立 widget
- 共享 `ErrorState`、`EmptyState`、`SectionCard`、`WorkbenchPageHeader` 等现有组件

**技术栈：** Flutter/Dart、sqflite、Provider、Material 3

---

## File Map

### Plan A — Notes 模块增强

**修改：**
- `lib/repositories/quick_note_repository.dart` — 新增 `searchByContactId` / `findPage`（分页）
- `lib/services/read/notes_read_service.dart` — 新增 `loadPage(page, filter)`、`NotesFilter` 值类型
- `lib/providers/notes_provider.dart` — 新增 filter 状态、`setFilter()`、`loadMore()`
- `lib/screens/notes/notes_overview_screen.dart` — 增加 filter bar、infinite scroll
- `lib/widgets/notes/notes_filter_bar.dart` — ✨新建
- `lib/widgets/notes/quick_note_card.dart` — 抽取独立卡片 widget（当前内嵌在 CaptureSessionGroup）

**测试：**
- `test/services/notes_read_service_filter_test.dart` — ✨新建

---

### Plan B — 首页 QC 摘要卡

**修改：**
- `lib/services/read/home_read_service.dart` — `HomeReadModel` 加 `todayNoteCount` + `recentNoteContacts`
- `lib/widgets/home/today_notes_summary_card.dart` — ✨新建
- `lib/widgets/home/home_overview_content.dart` — 在 `HomeStatRow` 之后插入卡片（有数据时才显示）

---

### Plan C — Info Tags 激活

**修改：**
- `lib/repositories/info_tag_repository.dart` — 新增 `searchContactsByTagName(keyword)`
- `lib/providers/global_search_provider.dart` — 新增 `_contactsByInfoTag` list、search 时调用
- `lib/widgets/search/global_search_results.dart` — 新增 info tag 命中结果区块
- `lib/services/read/contact_read_service.dart` — 新增 `getNotesForContact(contactId)`（或直接用 NotesReadService）
- `lib/screens/contacts/contact_detail_screen.dart` — 在 InfoTagsSection 下方增加联动笔记列表
- `lib/widgets/contact/contact_detail_notes_section.dart` — ✨新建

---

## 实施任务

---

### Task 1：NotesReadService 加分页与 filter

**目标：** 支持"按联系人筛选 + 分页"查询，为 Notes 无限滚动奠定基础。

**文件：**
- 修改：`lib/repositories/quick_note_repository.dart`
- 修改：`lib/services/read/notes_read_service.dart`

**步骤：**

- [ ] 1a. 在 `QuickNoteRepository` 抽象接口末尾追加：
  ```dart
  /// 分页查询（未软删），支持联系人过滤。
  /// [offset] 从 0 开始；[limit] 默认 30。
  /// [contactId] 非 null 时只返回关联该联系人的笔记。
  Future<List<QuickNote>> findPage({
    int offset = 0,
    int limit = 30,
    String? contactId,
  });
  ```
  `SqliteQuickNoteRepository` 实现：带 `WHERE` 条件（`deletedAt IS NULL`，可选 `linkedContactId = ?`），`ORDER BY createdAt DESC`，`LIMIT ? OFFSET ?`。

- [ ] 1b. 在 `notes_read_service.dart` 新增值类型：
  ```dart
  class NotesFilter {
    final String? contactId;  // null = 不过滤
    final String? contactName; // 仅用于 UI 显示
    const NotesFilter({this.contactId, this.contactName});
    NotesFilter get cleared => const NotesFilter();
    bool get isActive => contactId != null;
  }
  ```
  在 `NotesReadService` 接口加：
  ```dart
  Future<List<QuickNote>> loadPage(int page, NotesFilter filter);
  ```
  `DefaultNotesReadService` 实现：调用 `_noteRepository.findPage(offset: page * 30, limit: 30, contactId: filter.contactId)`，同时批量 resolve contactNames。

- [ ] 1c. 新建测试：`test/services/notes_read_service_filter_test.dart`
  - 构造 2 条有 `linkedContactId`、1 条无 `linkedContactId` 的 fake 数据
  - 断言过滤后只返回匹配的条目
  - 断言分页偏移正确

- [ ] 验证：`flutter test test/services/notes_read_service_filter_test.dart`

---

### Task 2：NotesProvider 加 filter 状态与无限滚动

**目标：** Provider 持有 filter、当前页、累积 notes 列表。

**文件：**
- 修改：`lib/providers/notes_provider.dart`

**步骤：**

- [ ] 2a. 新增私有字段：
  ```dart
  NotesFilter _filter = const NotesFilter();
  List<QuickNote> _allNotes = const [];
  int _currentPage = 0;
  bool _hasMore = true;
  ```
  对外暴露：`NotesFilter get filter`，`List<QuickNote> get allNotes`，`bool get hasMore`。

- [ ] 2b. 新增方法：
  ```dart
  Future<void> setFilter(NotesFilter filter) {
    _filter = filter;
    _currentPage = 0;
    _allNotes = const [];
    _hasMore = true;
    return _loadPage(0);
  }

  Future<void> loadMore() {
    if (!_hasMore || loading) return Future.value();
    return _loadPage(_currentPage + 1);
  }
  ```
  `_loadPage(int page)` 调用 `_readService.loadPage(page, _filter)`，追加到 `_allNotes`，若返回长度 < 30 则 `_hasMore = false`，更新 `_currentPage`。

- [ ] 2c. 保持 `loadToday()` / `navigateToDate()` 原有行为不变（它们走 `loadDay` 路径，与新路径正交）。

- [ ] 验证：`flutter analyze lib/providers/notes_provider.dart`

---

### Task 3：Notes 页面 filter bar 与无限滚动

**目标：** 在 Notes 页顶部加筛选入口；列表支持"加载更多"；不改动日期导航。

**文件：**
- 新建：`lib/widgets/notes/notes_filter_bar.dart`
- 修改：`lib/screens/notes/notes_overview_screen.dart`

**步骤：**

- [ ] 3a. 新建 `notes_filter_bar.dart`：
  ```dart
  class NotesFilterBar extends StatelessWidget {
    final NotesFilter filter;
    final VoidCallback onClear;
    // 仅当 filter.isActive 时显示 chip "联系人: ${filter.contactName}"+ × 按钮
  }
  ```
  filter 未激活时返回 `SizedBox.shrink()`，不占空间。
  chip 使用 `colorScheme.secondaryContainer`，和 group tags 区分。

- [ ] 3b. 在 `notes_overview_screen.dart` 的页面 header 下方（紧接 `WorkbenchPageHeader`）插入 `NotesFilterBar`。

- [ ] 3c. 改造 `_NotesView` 中的主列表：当 `provider.filter.isActive` 时改用 `provider.allNotes` 渲染（逐条展示 `QuickNoteCard`），否则保持原有按 session 分组的 `CaptureSessionGroup` 视图。

- [ ] 3d. 在列表末尾加 `_LoadMoreTrigger`：`provider.hasMore` 时显示 loading indicator，出现在屏幕时调用 `provider.loadMore()`（用 `VisibilityDetector` 或简单判断 scroll extent）。

- [ ] 验证：macOS 中打开 Notes 页，默认视图无变化；切换到联系人联动后可见 filter；列表滚动到底触发追加。

---

### Task 4：联系人详情 → Notes 过滤跳转

**目标：** 在联系人详情的 info tags section 下方展示"相关笔记"，点击笔记可跳转，且可从联系人详情页直接打开 Notes 页并激活该联系人的 filter。

**文件：**
- 新建：`lib/widgets/contact/contact_detail_notes_section.dart`
- 修改：`lib/screens/contacts/contact_detail_screen.dart`
- 修改：`lib/screens/contacts/contact_detail_actions.dart`（可选：加 openContactNotes action）

**步骤：**

- [ ] 4a. 新建 `contact_detail_notes_section.dart`：
  接收 `List<QuickNote> notes` 和 `VoidCallback onViewAll`。
  最多展示 3 条（最新），每条显示内容截断（2 行）+ 时间戳。
  底部"查看全部 N 条"按钮调用 `onViewAll`。
  空时返回 `SizedBox.shrink()`。

- [ ] 4b. `ContactDetailReadModel`（在 `contact_read_service.dart`）是否已包含 notes？若无，追加：
  ```dart
  final List<QuickNote> recentNotes;  // 最近 3 条，来自 NotesReadService.findByContactId
  ```
  在 `DefaultContactReadService.loadDetail` 中调用 `_notesReadService?.findByContactId(contactId)` 取前 3 条，注入为 `recentNotes`。
  `NotesReadService` 已有 `findByContactId`，直接复用。

- [ ] 4c. 在 `contact_detail_screen.dart` 的 `ContactDetailInfoTagsSection` 下方插入：
  ```dart
  ContactDetailNotesSection(
    notes: data.recentNotes,
    onViewAll: () => openNotesFilteredByContact(context, data.contact),
  ),
  ```

- [ ] 4d. 在 `contact_detail_actions.dart` 实现 `openNotesFilteredByContact(context, contact)`：
  切换到 Notes tab，并调用 `context.read<NotesProvider>().setFilter(NotesFilter(contactId: contact.id, contactName: contact.name))`。

- [ ] 验证：联系人详情页底部出现"相关笔记"区块（联系人有 note 时），点击"查看全部"跳转到 Notes 页且已激活 filter。

---

### Task 5：HomeReadModel 加今日笔记摘要

**目标：** 首页展示今天通过 Quick Capture 记了多少条，涉及哪些联系人。不改动现有首页区块位置。

**文件：**
- 修改：`lib/services/read/home_read_service.dart`
- 新建：`lib/widgets/home/today_notes_summary_card.dart`
- 修改：`lib/widgets/home/home_overview_content.dart`

**步骤：**

- [ ] 5a. 在 `HomeReadModel` 加字段：
  ```dart
  final int todayNoteCount;
  final List<String> todayNoteContactNames;  // 去重，最多 3 个
  ```
  `DefaultHomeReadService.loadWorkbench()` 中调用 `_quickNoteRepository.findByDate(today)`（已有），统计 count，从 contactIds 批量 resolve 名字（借用 `_contactRepository`，已有引用）。

- [ ] 5b. 新建 `today_notes_summary_card.dart`：
  一行卡片，左侧"📝 今天记了 N 条"，右侧若有联系人则显示头像/姓名气泡（最多 3 个，溢出显示 "+N"）。
  样式：`SectionCard` 包裹，高度约 56dp；使用 `AppColors` / `colorScheme` 现有 token。
  若 `todayNoteCount == 0` 则不渲染（返回 `SizedBox.shrink()`）。

- [ ] 5c. 在 `home_overview_content.dart` 的 `HomeStatRow` 和 `HomeWeekPlanSection` 之间插入：
  ```dart
  TodayNotesSummaryCard(
    count: data.todayNoteCount,
    contactNames: data.todayNoteContactNames,
    onTap: onOpenNotes,
  ),
  const SizedBox(height: AppSpacing.md),
  ```
  `onOpenNotes` 已有，直接复用。

- [ ] 验证：有 Quick Capture 记录的日期打开首页可见摘要卡；无记录时首页与改动前视觉完全一致。

---

### Task 6：Info Tags 接入全局搜索

**目标：** 在全局搜索中，当 keyword 命中某个 info tag 名时，返回持有该 tag 的联系人。

**文件：**
- 修改：`lib/repositories/info_tag_repository.dart`
- 修改：`lib/providers/global_search_provider.dart`
- 修改：`lib/widgets/search/global_search_results.dart`

**步骤：**

- [ ] 6a. 在 `InfoTagRepository` 接口追加：
  ```dart
  /// 返回 name 包含 keyword 的所有 info tags 对应的 contactId 列表（去重）。
  Future<List<String>> findContactIdsByTagKeyword(String keyword);
  ```
  `SqliteInfoTagRepository` 实现：
  ```sql
  SELECT DISTINCT cit.contactId
  FROM info_tags it
  JOIN contact_info_tags cit ON cit.infoTagId = it.id
  WHERE it.name LIKE ?
  ```
  参数 `'%$keyword%'`。

- [ ] 6b. 在 `GlobalSearchProvider` 的 `search()` 里，parallel 调用：
  ```dart
  final infoTagContactIds = await _infoTagRepository.findContactIdsByTagKeyword(normalizedKeyword);
  ```
  将 `infoTagContactIds` 去重后批量 `_contactService.getContactsByIds(ids)`（若不存在则新增该方法）。
  结果存入新字段 `List<Contact> _contactsByInfoTag`，暴露 getter；从现有 `_contacts` 中剔除重复（按 id）。

- [ ] 6c. 在 `GlobalSearchResults` 里新增区块（紧接联系人结果之后）：
  ```dart
  if (contactsByInfoTag.isNotEmpty)
    _SearchSection(title: '信息标签匹配', count: contactsByInfoTag.length, child: ...)
  ```
  每条显示联系人名 + 命中的 tag 名。点击走 `onContactTap`。

- [ ] 验证：搜索"33岁"，若有联系人持有该 info tag 则出现在"信息标签匹配"区块。

---

### Task 7：flutter analyze 全量验证

**步骤：**

- [ ] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze`
- [ ] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter test`
- [ ] 确认零新 error，已有 warning 不新增。

---

## 依赖顺序

```
Task 1 (repo + service) 
  └─> Task 2 (provider)
        └─> Task 3 (UI: filter bar + scroll)
              └─> Task 4 (contact detail ↔ notes)

Task 5 (home summary) — 独立，可并行

Task 6 (info tag search)
  └─> 需 Task 1 的 ContactService.getContactsByIds（或简单 in-memory filter）

Task 7 — 最后统一验证
```

Tasks 1-4 是一条主线。Task 5 独立，可优先做（改动小、价值快）。Task 6 依赖已有 info tag 数据，可在 Task 1-4 之后做。

---

## 明确不在本计划内

- Notes 全文搜索（已有，通过全局搜索覆盖，不再重复）
- Info tags 的手动编辑 UI（写入链路已通，手动修改留待后续专项）
- 联系人重要日期与笔记的联动（单独规划）
- Quick Capture 解析继续完善（单独迭代）
- iOS / Windows 构建适配
