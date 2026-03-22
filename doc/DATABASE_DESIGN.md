# Kongo 数据库设计

## 概览

- 数据库类型：SQLite
- 数据库文件：`kongo.db`
- 当前 schema 版本：`3`
- 当前持久化入口：`lib/services/database_service.dart`

当前数据库既承载现用模型，也保留少量历史兼容结构。文档需要同时说明“当前真实读写表”与“兼容遗留项”。

## 设计原则

1. 本地优先，所有核心数据默认离线可用
2. 核心实体用关系表表达，不把复杂聚合直接塞进单表字段
3. 附件本体存磁盘，数据库只存元数据与关联关系
4. 迁移优先保证旧数据可升级，再逐步清理兼容字段

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

索引：
- `idx_contacts_name`
- `idx_contacts_phone`
- `idx_contacts_email`
- `idx_contacts_createdAt`

### `tags`
标签主表。

关键字段：
- `id`
- `name`，唯一
- `color`
- `createdAt`
- `updatedAt`

索引：
- `idx_tags_name`

### `contact_tags`
联系人与标签的多对多关联表。

关键字段：
- `id`
- `contactId`
- `tagId`
- `addedAt`

约束：
- `UNIQUE(contactId, tagId)`
- 双外键均 `ON DELETE CASCADE`

### `event_types`
事件类型表。

关键字段：
- `id`
- `name`，唯一
- `icon`
- `color`
- `createdAt`
- `updatedAt`

默认种子：
- `生日`
- `会面`
- `通话`
- `跟进`

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

重要说明：
- 数据库层仍保留 `status TEXT NOT NULL DEFAULT 'planned'`
- 当前 Dart 运行时 `Event` 模型不再映射该字段
- 当前 UI、Service、Read Service 也不再基于状态做业务判断
- 因此 `status` 当前应被视为兼容字段，而不是活跃领域字段

索引：
- `idx_events_eventTypeId`
- `idx_events_status`
- `idx_events_startAt`
- `idx_events_createdByContactId`

### `event_participants`
事件与联系人的多对多关联表，并承载参与角色。

关键字段：
- `id`
- `eventId`
- `contactId`
- `role`
- `addedAt`

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
- 当前总结真实模型是 `DailySummary`
- 一天最多一条总结
- 文本被拆分为“当日总结”和“明日计划”

索引：
- `idx_daily_summaries_summaryDate`
- `idx_daily_summaries_source`
- `idx_daily_summaries_createdAt`

### `attachments`
附件元数据表。

关键字段：
- `id`
- `fileName`
- `originalFileName`
- `storagePath`
- `mimeType`
- `extension`
- `sizeBytes`
- `checksum`
- `previewText`
- `createdAt`
- `updatedAt`

说明：
- `storagePath` 指向应用私有目录中的真实文件
- 文件本体由 `AttachmentService` 复制到本地目录

索引：
- `idx_attachments_fileName`
- `idx_attachments_mimeType`
- `idx_attachments_checksum`

### `attachment_links`
附件与 owner 的关联表。

关键字段：
- `id`
- `attachmentId`
- `ownerType`
- `ownerId`
- `label`
- `addedAt`

当前 ownerType：
- `event`
- `summary`

约束：
- `UNIQUE(attachmentId, ownerType, ownerId)`

索引：
- `idx_attachment_links_attachmentId`
- `idx_attachment_links_owner`

### `ai_jobs` 与 `ai_outputs`
当前为预留表，尚未在主流程中启用。

用途：
- 记录 AI 任务调用元数据
- 记录 AI 输出内容

## 历史兼容结构

### `event_summaries`
这是旧版事件总结表，仅在从 v2 迁移到 v3 时读取与折叠，不再作为当前主模型写入表。

迁移策略：

1. 读取旧 `event_summaries`
2. 按 `createdAt` 所在日期归并
3. 生成新的 `daily_summaries`
4. 保留最后一条记录的主键与元数据
5. 把旧附件关联的 `ownerId` 重写到保留的总结 id

这意味着：
- 旧事件纪要不会完全原样保留为多条事件级总结
- 当前产品语义已经收敛为“按日期管理每日总结”

## 当前领域关系

```text
contacts ──< contact_tags >── tags

contacts ──< event_participants >── events ──> event_types

daily_summaries ──< attachment_links >── attachments
events          ──< attachment_links >── attachments
```

说明：
- 当前 `daily_summaries` 不直接挂在 `events` 下
- 当前联系人详情通过事件聚合拿到部分附件展示，但没有独立联系人附件表

## 运行时模型与数据库差异

### 事件状态差异
- DB 有 `events.status`
- Dart `Event` 无 `status`
- 当前文档与代码都应把它视作兼容字段

### 总结模型差异
- DB 当前主表是 `daily_summaries`
- 代码主模型是 `DailySummary`
- `EventSummary` 在代码中只是 `typedef` 到 `DailySummary` 的兼容别名

## 迁移说明

### v1 -> v2
- 从旧的 `contact_events` 迁移到 `events` 与 `event_participants`
- 初始化事件类型

### v2 -> v3
- 创建 `daily_summaries`
- 将旧 `event_summaries` 归并迁移到 `daily_summaries`

## 设计建议

1. 后续若彻底放弃状态语义，应补一次 schema 清理迁移，移除 `events.status`
2. 后续若恢复事件级总结，应明确区分“事件总结”和“每日总结”，不要复用现有表名与模型名
3. 若附件未来支持联系人直挂，应扩展 `attachment_links.ownerType`，不需要重建附件表