# Kongo 数据库设计

## 概览

- 数据库类型：SQLite
- 数据库文件：`kongo.db`
- 当前 schema 版本：9（已为 8 张核心表加入 `deletedAt` 软删除字段，预埋云同步基础）
- 持久化入口：`lib/services/database_service.dart`

## 设计原则

1. 本地优先，核心数据默认离线可用
2. 复杂关系优先用关系表表达，不把聚合硬塞单表
3. 附件本体存文件系统，数据库存元数据与关联关系
4. 迁移优先保证旧数据可升级，再逐步压缩兼容结构

## 当前主表

### `contacts`

联系人主表。

关键字段：

- `id`
- `name`
- `phone`
- `email`
- `address`
- `notes`
- `avatarPath`
- `createdAt`
- `updatedAt`

### `tags`

标签主表，`name` 唯一。

### `contact_tags`

联系人与标签的多对多关系表。

约束：

- `UNIQUE(contactId, tagId)`
- 双外键 `ON DELETE CASCADE`

### `event_types`

事件类型表。

默认种子：生日、会面、通话、跟进。

### `events`

事件主表。

关键字段：

- `id`
- `title`
- `eventTypeId`
- `startAt`
- `endAt`
- `location`
- `description`
- `reminderEnabled`
- `reminderAt`
- `createdByContactId`
- `createdAt`
- `updatedAt`

兼容字段：

- `status`

说明：

- 当前运行时 `Event` 模型不再映射 `status`
- 当前 UI、Service、Read Service 也不再按状态做业务判断

### `event_participants`

事件与联系人的多对多关系表，同时承载参与角色。

约束：

- `UNIQUE(eventId, contactId)`

### `daily_summaries`

当前主总结表。

关键字段：

- `id`
- `summaryDate`，唯一
- `todaySummary`
- `tomorrowPlan`
- `source`
- `createdByContactId`
- `aiJobId`
- `createdAt`
- `updatedAt`

说明：

- 当前真实总结模型是 `DailySummary`
- 每天最多一条总结

### `attachments`

附件元数据表。

关键字段：

- `id`
- `fileName`
- `originalFileName`
- `storagePath`
- `storageMode`
- `sourcePath`
- `managedPath`
- `snapshotPath`
- `mimeType`
- `extension`
- `sizeBytes`
- `originalSizeBytes`
- `managedSizeBytes`
- `checksum`
- `previewText`
- `previewStatus`
- `previewUpdatedAt`
- `previewError`
- `sourceStatus`
- `sourceLastVerifiedAt`
- `importPolicy`
- `createdAt`
- `updatedAt`

说明：

- 当前支持 `managed` / `linked` 两种存储模式
- `storagePath` 仍保留为兼容字段
- `previewStatus` / `previewUpdatedAt` / `previewError` 已在 schema 中稳定存在

### `attachment_links`

附件与 owner 的关联表。

当前 `ownerType`：

- `event`
- `summary`

约束：

- `UNIQUE(attachmentId, ownerType, ownerId)`

### `contact_milestones`

联系人重要日期表。

关键字段：

- `id`
- `contactId`
- `type`
- `label`
- `milestoneDate`
- `isLunar`
- `isRecurring`
- `reminderEnabled`
- `reminderDaysBefore`
- `notes`
- `createdAt`
- `updatedAt`

说明：

- 用于生日、纪念日、入职日、自定义重要日期等
- 当前联系人重要日期已进入首页、联系人列表和日历时间节点展示
- `isLunar` 当前仅做存储，尚未参与日历换算显示

### `app_preferences`

应用偏好表。

关键字段：

- `key`
- `value`
- `updatedAt`

说明：

- 当前用于持久化时间节点类别开关
- 现有 key 包括联系人重要日期与公共纪念日的显示开关

### `todo_groups`

待办组主表。

关键字段：

- `id`
- `title`
- `description`
- `sortOrder`
- `archivedAt`
- `createdAt`
- `updatedAt`

说明：

- 当前用于组织待办组视图
- 删除组时，组内待办项会级联删除

### `todo_items`

待办项主表。

关键字段：

- `id`
- `groupId`
- `parentItemId`
- `title`
- `notes`
- `status`
- `dueAt`
- `completedAt`
- `sourceType`
- `sourceId`
- `sortOrder`
- `createdAt`
- `updatedAt`

说明：

- 当前支持一级项 / 子项两层结构
- `sourceType` / `sourceId` 已预留给后续行动项来源映射

### `todo_item_contacts`

待办项与联系人的多对多关系表。

### `todo_item_events`

待办项与事件的多对多关系表。

### `ai_jobs` / `ai_outputs`

AI 任务与输出表，当前为基础设施预留，不是日常主流程核心表。

## 历史兼容结构

### `event_summaries`

这是旧版事件总结表。

当前状态：

- 仅用于旧版本迁移与兼容
- 当前不再作为主模型写入

## 当前缺失的结构

以下能力当前尚未进入数据库 schema：

1. **软删除字段 `deletedAt`** — 待 v9 迁移执行。将新增到 `contacts`、`tags`、`events`、`daily_summaries`、`attachments`、`contact_milestones`、`todo_groups`、`todo_items` 共 8 张表，为云同步预埋基础。实施计划见 `PLAN_SCHEMA_MIGRATION_V9.md`。
2. 外部节点源缓存表

这意味着：

- 当前时间节点类别开关已经进入通用偏好持久化阶段
- 当前仍缺节气、营销节点等外部节点源缓存或配置结构

## 当前领域关系

```text
contacts ──< contact_tags >── tags

contacts ──< contact_milestones

contacts ──< event_participants >── events ──> event_types

todo_groups ──< todo_items
todo_items ──< todo_item_contacts >── contacts
todo_items ──< todo_item_events >── events

daily_summaries ──< attachment_links >── attachments
events          ──< attachment_links >── attachments
```

## 迁移历史

### v1 → v2

- 引入事件、参与人、旧版事件总结、附件、AI 表
- 初始化默认事件类型

### v2 → v3

- 创建 `daily_summaries`
- 将 `event_summaries` 归并迁移到 `daily_summaries`

### v3 → v4

- 创建 `contact_milestones`

### v4 → v5

- 扩展 `attachments`，支持 `managed` / `linked` 混合存储元数据

### v5 → v6

- 为 `attachments` 增加预览状态字段：
  `previewStatus`、`previewUpdatedAt`、`previewError`

### v6 → v7

- 创建 `app_preferences`
- 将时间节点类别开关持久化到本地数据库

### v7 → v8

- 创建 `todo_groups`
- 创建 `todo_items`
- 创建 `todo_item_contacts` 与 `todo_item_events`

## 当前设计建议

1. 后续若彻底放弃事件状态语义，应补 schema 清理迁移，移除 `events.status`
2. 后续若需要待办排序拖拽与跨组移动，应补充更明确的排序策略和批量更新接口
3. 后续若时间节点来源继续扩展，应补充外部节点源缓存结构，并评估是否需要从通用偏好表拆出专门配置表
