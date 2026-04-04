# Quick Capture 细节修复实施计划

**Goal:** 修复快速输入中已确认的全部 bug，共 7 个独立可测任务。所有 AI system prompt 改动集中在 Task 5，其余 task 不得触碰 prompt 字符串。

**Architecture:** Swift 状态栏弹窗（`QuickCaptureStatusItem.swift`）↔ MethodChannel ↔ Dart 路由（`quick_capture_router.dart`）↔ `_handleSave`（`main.dart`）

**Tech Stack:** Swift / AppKit，Dart / Flutter，sqflite，AI service

---

## File Map

**Modify:**
- `macos/Runner/QuickCaptureStatusItem.swift`
- `lib/services/quick_capture_router.dart`
- `lib/main.dart`

**Create (test):**
- `test/services/quick_capture_router_test.dart`

**Out of scope:**
- UI redesign / 新增页面
- 联系人/事件模块以外的刷新逻辑
- Windows / iOS 平台适配

---

## Tasks

---

### Task 1：Swift 小修复（占位符、队列徽章、保存时序）

**覆盖问题：** #8 占位符缺 Cmd、#6 队列徽章少一、#15 `saveDirectly` 延迟不一致

**Files:**
- Modify: `macos/Runner/QuickCaptureStatusItem.swift`

#### 步骤

- [ ] **1.1** 修复 `resetToInput()` 随机占位符池。  
  找到 `let placeholders = [...]` 数组，把其中含 `"（按 Return 保存）"` 的条目统一改为 `"（按 Cmd+Return 提交）"`。确认池里所有条目的快捷键提示与 `loadView` 固定占位符保持一致。

- [ ] **1.2** 修复队列徽章计数。  
  找到 `updateQueueBadge()` 的调用和实现。将徽标值改为 `pendingQueue.count + 1`（当前正在处理的 +1），而不是 `pendingQueue.count`。仅在 `processNextInQueue` 开始处（取出队首之前）更新一次即可。

- [ ] **1.3** 统一保存成功后关闭 popover 的延迟。  
  找到 `saveDirectly` 中的 `DispatchQueue.main.asyncAfter(deadline: .now() + 1.5)`，改为 `+ 1.0`，与 `quickCaptureDidConfirm` 路径一致。

- [ ] **1.4** 构建并启动 macOS UI，手动验证三项：
  1. 焦点在输入框时，重复触发快捷键多次，观察占位符文字是否全部含"Cmd+Return"。
  2. 在多日期场景（输入多个日期相关事件）下确认后，状态栏徽章数字是否正确（第一条确认时显示总数 N，每完成一条减 1）。
  3. 直接保存（`saveDirectly` 路径）后 popover 消失时间与确认路径一致。

---

### Task 2：事件关联 segment 状态修复

**覆盖问题：** #4 点击已有事件按钮后 segment 错误跳到"跳过"

**Files:**
- Modify: `macos/Runner/QuickCaptureStatusItem.swift`

**设计决策：** 将事件操作 segment 从 2 项（"创建事件" / "跳过"）改为 3 项（"创建事件" / "关联已有" / "跳过"），index 语义如下：
- 0 = `create`
- 1 = `link`（选中某个已有事件）
- 2 = `skip`

#### 步骤

- [ ] **2.1** 找到 `buildEventSection` 中创建 `NSSegmentedControl` 的代码。  
  在现有 2 段基础上插入第二段"关联已有"，调整各段宽度使布局对称。示例修改：
  ```swift
  // Before
  eventActionSegmentControl?.setLabel("创建事件", forSegment: 0)
  eventActionSegmentControl?.setLabel("跳过", forSegment: 1)
  // After
  eventActionSegmentControl = NSSegmentedControl(labels: ["创建事件", "关联已有", "跳过"],
                                                  trackingMode: .selectOne,
                                                  target: self,
                                                  action: #selector(eventActionSegmentChanged(_:)))
  ```
  确保 `segmentCount` 为 3，默认选中 index 0。

- [ ] **2.2** 更新 `eventActionSegmentChanged(_:)`：
  ```swift
  switch sender.selectedSegment {
  case 0:
      eventAction = "create"; selectedEventId = nil
  case 1:
      eventAction = "link"
      // 不清空 selectedEventId —— 用户切到此段后需再点选某个事件按钮
  case 2:
      eventAction = "skip"; selectedEventId = nil
  default: break
  }
  for btn in eventLinkButtons { btn.state = .off }
  ```

- [ ] **2.3** 更新 `eventLinkTapped(_:)`：  
  将 `eventActionSegmentControl?.selectedSegment = 1` 保留（现在 index 1 = "关联已有"，语义正确，无需修改赋值行本身，但确认 `eventAction = "link"` 仍在该方法中被设置）。

- [ ] **2.4** 检查 `confirmTapped` 里 `eventAction` 的全部分支，确认 `"link"` / `"create"` / `"skip"` 三个字符串值没有变化（此处不需改动）。

- [ ] **2.5** 手动验证：输入含事件日期的文本 → 解析后确认页 → 点一个已有事件按钮 → segment 应切换至"关联已有"（index 1），而不是"跳过"。点击"创建事件"或"跳过"应清除已有事件选中状态。

---

### Task 3：Dart `_handleSave` 三项修复

**覆盖问题：** #2 多事件 note 只关联第一个事件、#12 事件创建后不刷新 events 列表、#13 info tags 写入后 contacts 刷新未 await

**Files:**
- Modify: `lib/main.dart`

#### 步骤

- [ ] **3.1** 找到 `_handleSave` 中的多事件创建循环（`for (final title in newEventTitles)`）。  
  将 `linkedEventId ??= newEvent.id` 改为将所有新事件 ID 收集到 `List<String> newEventIds`，在循环结束后单独处理 note 的关联逻辑（note 仍只能关联一个主事件，选第一个 ID）：
  ```dart
  // Before
  linkedEventId ??= newEvent.id;

  // After: collect all IDs, use first for note link
  newEventIds.add(newEvent.id);
  // After the loop:
  linkedEventId = newEventIds.isNotEmpty ? newEventIds.first : linkedEventId;
  ```
  注意：note 表结构只有单个 `linkedEventId` 字段，此处只能存一个；但这样能保证"第一个事件"赋值路径明确，不依赖 `??=` 的执行顺序。

- [ ] **3.2** 在 `_handleSave` 创建事件后立即刷新 events 提供器。  
  找到 `notesProvider.refresh()` 调用处，在其后补充：
  ```dart
  if (mounted) {
    context.read<EventsListProvider>().loadEvents();
  }
  ```
  确认 `EventsListProvider` 已在该文件作用域内可访问（`context.read`）。

- [ ] **3.3** 找到 `infoTagService.applyTagsToContact(...)` 的调用，确保其后的 `contactProvider.loadContacts()` 有 `await`：
  ```dart
  await infoTagService.applyTagsToContact(linkedContactId, tags);
  await contactProvider.loadContacts();  // 补充 await
  ```

- [ ] **3.4** 运行 `flutter analyze` 确认无新引入提示或错误：
  ```bash
  source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze
  ```

---

### Task 4：Router 代码修复（非 prompt 改动）

**覆盖问题：** #5 aiFallback 永远 false、#7 eventGroups 单组被忽略、#11 contactId 死代码、#3 AI 路径不做 fuzzy match、#14 多日期 N 次串行 DB 查询

**Files:**
- Modify: `lib/services/quick_capture_router.dart`
- Create: `test/services/quick_capture_router_test.dart`

#### 步骤

- [ ] **4.1** 修复 `aiFallback` 标志。  
  在本地解析路径末尾（`response['aiFallback'] = false;` 所在行），改为：
  ```dart
  response['aiFallback'] = attemptedAi;
  ```
  `attemptedAi` 变量在函数顶部已声明，AI 被尝试但失败时为 `true`，AI 未启用时为 `false`，无需其他改动。

- [ ] **4.2** 修复 `eventGroups` 单组被忽略。  
  找到条件 `if (rawEventGroups is List && rawEventGroups.length > 1)`，改为 `>= 1`：
  ```dart
  if (rawEventGroups is List && rawEventGroups.isNotEmpty) {
  ```
  `multiResult` 只在 `items.length > 1` 时才有意义；保持返回逻辑：单组时直接走常规单条目路径。调整如下：单组 items 构建完后，若 `items.length == 1`，解包该 item 作为普通 response 返回，而不是返回 `{multiResult: true}`：
  ```dart
  if (items.isNotEmpty) {
    if (items.length == 1) return items.first;         // 单组退化为普通响应
    return {'multiResult': true, 'items': items};      // 多组走队列
  }
  ```

- [ ] **4.3** 删除死代码 `contactId` 检查分支。  
  找到 AI 路径中：
  ```dart
  final contactId = parsed['contactId'] as String?;
  ...
  if (contactId != null) {
    response['hasContact'] = true;
    response['contactType'] = 'matched';
    ...
    response['contactId'] = contactId;
  } else if (contactName != null ...
  ```
  移除 `contactId` 变量声明和整个 `if (contactId != null)` 分支，只保留 `else if` 成为普通 `if`。这简化了代码且不影响任何运行时路径（AI 从不返回此字段）。

- [ ] **4.4** AI 路径补充 fuzzy match。  
  AI 成功返回 `contactName` 后，当前代码一律设置 `contactType: 'candidate'`。在该处补充本地解析时已有的 fuzzy match 逻辑：  
  a. 调用 `QuickCaptureParser().tryFuzzyMatchByName(contactName, contacts)`（如果该方法是私有的，提取为 package-level 辅助函数或在 router 里直接内联简单匹配：遍历 contacts，检查 `contact.name == contactName` 或包含关系）。  
  b. 若匹配成功：`contactType = 'matched'`，`contactId = matchedContact.id`。  
  c. 若未匹配：保持 `contactType = 'candidate'`（现有行为不变）。  

  最简单的实现：
  ```dart
  final matched = contacts.where((c) =>
      c.name == contactName ||
      c.name.contains(contactName) ||
      contactName.contains(c.name)
  ).firstOrNull;
  if (matched != null) {
    response['contactType'] = 'matched';
    response['contactId'] = matched.id;
  }
  ```

- [ ] **4.5** 多日期组 DB 查询改为先收集唯一日期再批量查询。  
  在 `for rawGroup in rawEventGroups` 循环**之前**，提取所有不重复的 `groupDate`，并发获取：
  ```dart
  final uniqueDates = rawEventGroups
      .whereType<Map>()
      .map((g) => g['date'] as String?)
      .whereType<String>()
      .toSet();
  final dateEventsMap = Map.fromEntries(
    await Future.wait(uniqueDates.map((ds) async {
      final d = DateTime.tryParse(ds);
      if (d == null) return MapEntry(ds, <Event>[]);
      return MapEntry(ds, await fetchEventsByDate(d));
    })),
  );
  ```
  在循环内用 `dateEventsMap[groupDateStr] ?? []` 替换 `await fetchEventsByDate(groupDate)`。

- [ ] **4.6** 编写 router 测试文件 `test/services/quick_capture_router_test.dart`，覆盖以下场景：
  - `aiFallback = true` 当 AI `isAvailable = true` 但抛出异常
  - `aiFallback = false` 当 `useAi = false`
  - `eventGroups` 单条目返回普通 response（非 multiResult）
  - `eventGroups` 2+ 条目返回 `multiResult: true`
  - AI 返回 contactName 且本地有同名联系人 → `contactType == 'matched'`

- [ ] **4.7** 运行路由测试：
  ```bash
  source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter test test/services/quick_capture_router_test.dart
  ```

---

### Task 5：AI system prompt 集中修订（本计划唯一的 prompt 改动任务）

**覆盖问题：** prompt 相关的全部问题：#11 schema 含无效 contactId 字段、#9 eventTitles fallback 使用全文、#7 eventGroups 单组语义模糊、#1 contactInfoTags 跨人混淆的预防

**Files:**
- Modify: `lib/services/quick_capture_router.dart`（仅 `systemPrompt` 字符串，不改逻辑代码）

**注意：** 此 task 只允许修改 `systemPrompt` 常量/变量，一次性完成全部 prompt 改动，后续 task 不再触碰 prompt。

#### 步骤

- [ ] **5.1** 从 schema 中彻底删除 `contactId` 字段描述。  
  当前 schema 注释中若残留 `contactId` 字段说明，一并删除。AI 的职责只是返回 `contactName`，匹配工作由 Dart 代码完成（Task 4.4）。

- [ ] **5.2** 加强 `eventTitles` 字段说明，防止 AI 在没有明确事件标题时将全文塞入。  
  在 `eventTitles` 规则后补充：
  > **Do NOT use the entire input as an event title.** If no clear event or task title can be extracted, set `eventTitles` to null. Use short, action-oriented phrases only (aim for < 20 characters per title).

- [ ] **5.3** 明确 `eventGroups` 可以只有 1 个条目。  
  在 `eventGroups` 规则段加一句：
  > `eventGroups` MAY contain only one entry. Use it whenever the input contains explicit per-date grouping, even for a single date, to preserve the date-to-titles association.

- [ ] **5.4** 加强 `contactInfoTags` 的 `contact` 字段精确性要求，避免跨人混淆。  
  在 `contactInfoTags` 规则后补充：
  > The `contact` field MUST exactly match the name as it appears in the input. Do not infer or merge attributes from one person onto another. Each entry should only contain facts clearly attributable to that specific person.

- [ ] **5.5** 在 debug build 下复制一份当前对话并对比 AI 输出，确认：
  1. 无 `contactId` 字段出现在 AI 响应中。
  2. 输入"今天跟王总沟通了很久业务细节，顺便了解到他最近在关注东南亚市场"时，`eventTitles` 不返回完整句子，或返回 null。
  3. 输入"和张三明天下午开会，和李四周五上午面试候选人" → `eventGroups` 包含 2 条，`contact` 分别精确匹配"张三"/"李四"。

---

### Task 6：信息标签按联系人分组关联（数据正确性核心修复）

**覆盖问题：** #1 pendingInfoTags 展平跨联系人标签导致错挂

**Files:**
- Modify: `macos/Runner/QuickCaptureStatusItem.swift`
- Modify: `lib/main.dart`

#### 设计

将 Swift 内部存储从 `pendingInfoTags: [String]` 改为 `pendingStructuredInfoTags: [[String: Any]]`，格式与 AI 原始输出一致：`[{contact: "张三", tags: ["CTO", "45岁"]}, ...]`。`confirmTapped` 发送结构化数据；`_handleSave` 在写入前根据 linked contact 的名字过滤出匹配条目的 tags。

#### 步骤

**Swift 侧（QuickCaptureStatusItem.swift）：**

- [ ] **6.1** 将成员变量 `var pendingInfoTags: [String]` 替换为：
  ```swift
  var pendingStructuredInfoTags: [[String: Any]] = []
  ```

- [ ] **6.2** 更新 `showConfirm` 中填充 `pendingInfoTags` 的逻辑。  
  当前代码从 `contactInfoTags([{contact, tags}])` 中提取 tags 展平存储。  
  改为直接存整个数组：
  ```swift
  if let rawTags = result["contactInfoTags"] as? [[String: Any]], !rawTags.isEmpty {
      pendingStructuredInfoTags = rawTags
  }
  ```

- [ ] **6.3** 重写 `buildInfoTagsSection()`，按 contact 分组展示，每组有小标题：
  ```swift
  for entry in pendingStructuredInfoTags {
      guard let contactName = entry["contact"] as? String,
            let tags = entry["tags"] as? [String] else { continue }
      // 添加联系人小标题 label
      // 再添加该联系人的 tag chip 行
  }
  ```
  删除按 tag 的 index 标记；改为按 `(entryIndex, tagIndex)` 的二维定位删除。

- [ ] **6.4** 更新 `infoTagDeleteTapped(_:)`：  
  将 `sender.tag` 改为自定义结构（可用 `tag = entryIndex * 100 + tagIndex` 简单编码），在删除时从对应 entry 的 tags 数组中移除。删除后调用 `rebuildInfoTagsSection()` 重新渲染。若某 entry 的 tags 全部删完，移除该 entry。

- [ ] **6.5** 更新 `confirmTapped` 发送结构化数据：
  ```swift
  if !pendingStructuredInfoTags.isEmpty {
      args["infoTags"] = pendingStructuredInfoTags
  }
  ```

- [ ] **6.6** 更新 `clearConfirmUI` 清除新变量：
  ```swift
  pendingStructuredInfoTags = []
  ```

**Dart 侧（lib/main.dart）：**

- [ ] **6.7** 更新 `_handleSave` 中处理 `infoTags` 的逻辑。  
  `infoTags` 现在是 `List<Map>` 而非 `List<String>`。根据 `linkedContactId` 对应联系人的名字（在 handle save 上下文中能拿到已链接联系人），过滤命中的 entry：
  ```dart
  final rawInfoTags = args['infoTags'];
  if (rawInfoTags is List && linkedContactId != null) {
    final linkedContact = await _contactRepository.findById(linkedContactId);
    final linkedName = linkedContact?.name ?? '';
    final List<String> matchedTags = [];
    for (final entry in rawInfoTags.whereType<Map>()) {
      final entryContact = entry['contact']?.toString() ?? '';
      // 联系人名字包含关系匹配（兼容 AI 返回全名 vs 简称）
      if (linkedName.isNotEmpty &&
          (entryContact == linkedName ||
           linkedName.contains(entryContact) ||
           entryContact.contains(linkedName))) {
        final tags = entry['tags'];
        if (tags is List) matchedTags.addAll(tags.map((t) => t.toString()));
      }
    }
    if (matchedTags.isNotEmpty) {
      await infoTagService.applyTagsToContact(linkedContactId, matchedTags);
      await contactProvider.loadContacts();
    }
  }
  ```
  删除原有的扁平 `List<String>` 处理路径。

- [ ] **6.8** 运行 flutter analyze 确认无类型错误：
  ```bash
  source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze
  ```

- [ ] **6.9** 手动端到端验证：
  1. 输入"明天张三来谈融资，他是 45 岁的 CTO，李四是他的助理"。
  2. 解析后确认页显示信息标签，按联系人分两组呈现（张三组 / 李四组）。
  3. 只关联张三 → 确认 → 在张三联系人详情中只出现"45岁"、"CTO"等张三的标签，不出现"助理"。

---

### Task 7：Info tags section 动态高度

**覆盖问题：** #10 多行标签时 popover 内容被截断

**Files:**
- Modify: `macos/Runner/QuickCaptureStatusItem.swift`

#### 步骤

- [ ] **7.1** 找到 `preferredContentHeight`（或 `updatePreferredContentSize`）相关逻辑。  
  当前 info tags 区域固定加 44pt。改为动态计算：
  ```swift
  let tagCount  = pendingStructuredInfoTags.flatMap { $0["tags"] as? [String] ?? [] }.count
  let tagRows   = max(1, Int(ceil(Double(tagCount) / 4.0)))  // 每行约 4 个标签
  let tagsHeight = tagRows > 0 ? 20 + tagRows * 28 : 0       // header 20 + 每行 28
  ```
  将这个 `tagsHeight` 替换原来的固定值参与高度总计。

- [ ] **7.2** 在 info tags section 增删标签后调用一次 `updatePreferredContentSize()`，确保 popover 即时响应高度变化。

- [ ] **7.3** 手动验证：构造至少 8 个标签的场景，确认所有标签在 popover 内可完整显示，无截断。

---

## 全量验证（所有 task 完成后）

```bash
# 静态分析
source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze

# 所有测试
source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter test

# 构建 macOS
source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter build macos
```

---

## 执行顺序建议

| 顺序 | Task | 原因 |
|------|------|------|
| 1st | Task 1 | 独立，风险最低，快速验证流程 |
| 2nd | Task 2 | 纯 Swift UI，独立可测 |
| 3rd | Task 3 | 纯 Dart，独立 |
| 4th | Task 4 | 改路由逻辑，需配测试 |
| 5th | Task 5 | Prompt 集中修改，基于 Task 4 新的结构 |
| 6th | Task 6 | 依赖 Task 5 对 contactInfoTags 的 prompt 加强，且改动最多 |
| 7th | Task 7 | 依赖 Task 6 的数据结构变更 |
