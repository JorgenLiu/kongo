# Schema Migration v9 Implementation Plan

**Goal:** 为所有核心实体表添加 `deletedAt INTEGER` 字段，为未来云同步软删除预埋基础。

**Architecture:** 纯数据库层变更——仅修改 schema DDL 和迁移脚本，不触及仓库或业务层。所有现有行的 `deletedAt` 默认为 NULL，语义为"未删除"，无需数据迁移。

**Tech Stack:** sqflite, `lib/services/migrations/`

---

## File Map

- Modify: `lib/services/database_service.dart`
- Modify: `lib/services/migrations/database_schema.dart`
- Modify: `lib/services/migrations/database_migrations.dart`

## Out of Scope

- 仓库层的软删除查询（`WHERE deletedAt IS NULL`）——属于云同步实现任务
- 写入时自动设置 `deletedAt`——同上
- 任何 UI 变更

---

## Tasks

### Task 1: 升级版本号

**Files:**
- Modify: `lib/services/database_service.dart`

- [ ] 将 `databaseVersion` 从 `8` 改为 `9`

---

### Task 2: 更新建表 DDL（新安装路径）

**Files:**
- Modify: `lib/services/migrations/database_schema.dart`

对以下 8 张表的 `CREATE TABLE` 常量，在 `updatedAt INTEGER NOT NULL` 之后追加 `deletedAt INTEGER`：

- [ ] `createContactsTable` — 在 `updatedAt INTEGER NOT NULL` 后加一行 `deletedAt INTEGER`
- [ ] `createTagsTable` — 同上
- [ ] `createEventsTable` — 同上（注意：events 末尾是 FOREIGN KEY 子句，`deletedAt` 插入 FK 约束之前）
- [ ] `createDailySummariesTable` — 同上（FK 约束之前）
- [ ] `createAttachmentsTable` — 同上
- [ ] `createContactMilestonesTable` — 同上（FK 约束之前）
- [ ] `createTodoGroupsTable` — 在 `updatedAt INTEGER NOT NULL` 后加一行 `deletedAt INTEGER`
- [ ] `createTodoItemsTable` — 同上（FK 约束之前）

> **格式参考：**
> ```sql
> createdAt INTEGER NOT NULL,
> updatedAt INTEGER NOT NULL,
> deletedAt INTEGER
> ```
> 有 FK 约束的表：
> ```sql
> updatedAt INTEGER NOT NULL,
> deletedAt INTEGER,
> FOREIGN KEY (contactId) REFERENCES contacts(id) ON DELETE CASCADE
> ```

---

### Task 3: 添加增量迁移函数

**Files:**
- Modify: `lib/services/migrations/database_migrations.dart`

- [ ] 在 `migrateToVersion8` 函数之后添加以下函数：

```dart
// ──────────────────── v8 → v9 ────────────────────

Future<void> migrateToVersion9(Database db) async {
  final batch = db.batch();
  for (final table in const [
    'contacts',
    'tags',
    'events',
    'daily_summaries',
    'attachments',
    'contact_milestones',
    'todo_groups',
    'todo_items',
  ]) {
    batch.execute('ALTER TABLE $table ADD COLUMN deletedAt INTEGER');
  }
  await batch.commit(noResult: true);
}
```

- [ ] 在 `onUpgradeDatabase` 函数中，`if (oldVersion < 8)` 块之后追加：

```dart
  if (oldVersion < 9) {
    await migrateToVersion9(db);
  }
```

---

### Task 4: 验证

- [ ] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze`
  - 期望：无新增错误或警告
- [ ] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter test`
  - 期望：全部通过（迁移仅加 nullable 列，不破坏现有查询）
- [ ] 手动检查：确保 `databaseVersion == 9`，`onUpgradeDatabase` 中迁移链完整（1..9 全部覆盖）
