# Kongo 内部接口规范

## 目的

本文档描述当前代码中真实存在的分层契约，而不是早期设想版本。

当前主分层如下：

```text
Screen -> Widget / Action -> Provider -> Read Service / Service -> Repository -> SQLite / File System
```

## 通用约束

### Screen
- 负责页面编排、导航入口、状态选择
- 不直接编排多段数据库聚合查询

### Provider
- 管理页面状态、异步流程、错误与初始化标记
- 写流程依赖 `Service`
- 读聚合优先依赖 `ReadService`

### Service
- 封装业务规则、校验、跨 repository 编排
- 不直接依赖 UI

### Read Service
- 只负责只读聚合
- 不承载 create / update / delete 规则

### Repository
- 负责 SQLite CRUD 与批量查询
- 不承载业务规则

## 异常模型

当前统一异常层定义在 `lib/exceptions/app_exception.dart`。

### 基类
```dart
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final Exception? originalException;
}
```

### 已实现子类
- `DatabaseException`
- `ValidationException`
- `BusinessException`
- `FileStorageException`
- `AiException`

### 返回约定
- 查询列表返回空列表，不返回 `null`
- 查询单对象通常抛异常，不返回空对象
- 创建 / 更新方法返回最终落库对象
- 仅少量明确允许“缺失即正常”的接口返回可空值，例如 `getSummaryByDate()`

## Service 契约

### ContactService
职责：联系人 CRUD、关键字搜索、按标签过滤、联系人视角读取事件与标签。

当前接口：

```dart
abstract class ContactService {
  Future<List<Contact>> getContacts();
  Future<Contact> getContact(String id);
  Future<Contact> createContact(ContactDraft draft);
  Future<Contact> updateContact(Contact contact, {List<String>? tagIds});
  Future<void> deleteContact(String id);
  Future<List<Contact>> searchByKeyword(String keyword);
  Future<List<Contact>> searchByTags(List<String> tagIds);
  Future<List<Event>> getContactEvents(String contactId);
  Future<List<Tag>> getContactTags(String contactId);
}
```

规则：
- 联系人名称必填
- `updateContact` 可顺带同步标签集合

### TagService
职责：标签 CRUD 与联系人打标。

```dart
abstract class TagService {
  Future<List<Tag>> getTags();
  Future<Tag> getTag(String id);
  Future<Tag> createTag(TagDraft draft);
  Future<Tag> updateTag(Tag tag);
  Future<void> deleteTag(String id);
  Future<void> addTagToContact(String contactId, String tagId);
  Future<void> removeTagFromContact(String contactId, String tagId);
  Future<List<Tag>> getContactTags(String contactId);
  Future<int> getContactCountByTag(String tagId);
}
```

### EventService
职责：事件本体、事件类型、参与人写侧规则。

```dart
abstract class EventService {
  Future<List<EventType>> getEventTypes();
  Future<EventType> createEventType(EventTypeDraft draft);
  Future<List<Event>> getEvents();
  Future<Event> getEvent(String id);
  Future<Event> createEvent(EventDraft draft);
  Future<Event> updateEvent(Event event);
  Future<void> deleteEvent(String id);
  Future<void> setParticipants(String eventId, List<String> contactIds, {Map<String, String>? participantRoles});
  Future<void> addParticipant(String eventId, String contactId, {String? role});
  Future<void> removeParticipant(String eventId, String contactId);
  Future<List<Contact>> getParticipants(String eventId);
  Future<Map<String, List<Contact>>> getParticipantsByEventIds(List<String> eventIds);
  Future<List<Event>> searchEvents({String? keyword, String? eventTypeId});
  Future<List<Event>> getUpcomingEvents({int days = 30});
}
```

规则：
- 事件标题必填
- 事件至少保留一个参与人
- 校验时间范围合法性
- 当前不包含 `status` 参数与状态流转规则

### SummaryService
职责：每日总结 CRUD、日期唯一约束、行动项提取。

```dart
abstract class SummaryService {
  Future<List<DailySummary>> getSummaries();
  Future<List<DailySummary>> searchByKeyword(String keyword);
  Future<DailySummary?> getSummaryByDate(DateTime summaryDate);
  Future<DailySummary> getSummary(String id);
  Future<DailySummary> createSummary(DailySummaryDraft draft);
  Future<DailySummary> updateSummary(DailySummary summary);
  Future<void> deleteSummary(String id);
  Future<List<ActionItem>> extractActionItemsFromSummary(String summaryId);
}
```

规则：
- `todaySummary` 与 `tomorrowPlan` 至少填一项
- 每天只允许一条总结

### AttachmentService
职责：附件落盘、元数据写入、owner 绑定、打开、删除。

```dart
abstract class AttachmentService {
  Future<List<Attachment>> getAllAttachments();
  Future<Attachment> saveAttachment(AttachmentDraft draft);
  Future<Attachment> getAttachment(String id);
  Future<Attachment> updateAttachment(Attachment attachment);
  Future<void> deleteAttachment(String id);
  Future<void> openAttachment(Attachment attachment);
  Future<void> removeAttachmentFromOwner(String attachmentId, AttachmentOwnerType ownerType, String ownerId, {bool deleteIfOrphan = false});
  Future<void> linkAttachmentToEvent(String attachmentId, String eventId, {String? label});
  Future<void> linkAttachmentToSummary(String attachmentId, String summaryId, {String? label});
  Future<void> unlinkAttachment(String attachmentId, AttachmentOwnerType ownerType, String ownerId);
  Future<List<Attachment>> getEventAttachments(String eventId);
  Future<Map<String, List<Attachment>>> getEventAttachmentsByEventIds(List<String> eventIds);
  Future<List<Attachment>> getSummaryAttachments(String summaryId);
  Future<Map<String, List<Attachment>>> getSummaryAttachmentsBySummaryIds(List<String> summaryIds);
}
```

规则：
- 附件源文件必须存在
- 直接删除前会检查是否仍有 owner 关联
- `openAttachment` 按平台走系统默认打开方式

## Read Service 契约

### ContactReadService
职责：联系人详情页只读聚合。

```dart
abstract class ContactReadService {
  Future<ContactDetailReadModel> getContactDetail(String contactId);
}

class ContactDetailReadModel {
  final Contact contact;
  final List<Tag> tags;
  final List<Event> events;
  final List<Attachment> attachments;
  final Map<String, String> eventTypeNames;
}
```

说明：
- 当前不包含独立 summaries 字段
- 联系人详情中的附件展示来自事件附件聚合

### EventReadService
职责：事件列表与详情页只读聚合。

```dart
abstract class EventReadService {
  Future<EventsListReadModel> getEventsList({String? contactId});
  Future<EventsListReadModel> searchEventsList({String? contactId, String? keyword, String? eventTypeId});
  Future<EventDetailReadModel> getEventDetail(String eventId);
}
```

读模型：

```dart
class EventsListReadModel {
  final Contact? contact;
  final List<EventListItemReadModel> items;
}

class EventListItemReadModel {
  final Event event;
  final String? eventTypeName;
  final List<String> participantNames;
}

class EventDetailReadModel {
  final Event event;
  final String? eventTypeName;
  final List<Contact> participants;
  final List<EventParticipantDetailReadModel> participantEntries;
  final List<Attachment> attachments;
  final Contact? createdByContact;
}
```

说明：
- 当前事件详情 read model 不包含每日总结列表
- 事件列表搜索支持 `keyword + eventTypeId`

## Provider 契约

### 基础设施
- `BaseProvider`：统一 `loading`、`initialized`、`error`、`execute()`
- `ProviderError`：将异常转换为可展示错误结构

### 已实现 Provider
- `ContactProvider`
- `ContactDetailProvider`
- `EventProvider`
- `EventsListProvider`
- `EventDetailProvider`
- `TagProvider`
- `SummaryProvider`
- `AttachmentProvider`
- `FilesProvider`
- `GlobalSearchProvider`

### 当前关注点

#### EventsListProvider
- 持有关键字
- 持有选中的事件类型过滤器
- 依赖 `EventReadService + EventService`

#### SummaryProvider
- 管理列表、当前详情、行动项
- 支持关键字过滤与按日期加载

#### FilesProvider
- 管理文件库附件列表与关键字过滤

#### GlobalSearchProvider
- 聚合联系人、事件、每日总结
- 承担命中排序与评分逻辑

## Repository 契约

当前 repository 为 SQLite 实现，主要职责如下：

- `ContactRepository`：联系人 CRUD、关键字搜索、按标签搜索
- `TagRepository`：标签 CRUD、联系人标签关系
- `EventRepository`：事件 CRUD、事件类型、参与人、搜索、即将发生事件
- `SummaryRepository`：每日总结 CRUD、按日期读取、关键字搜索
- `AttachmentRepository`：附件 CRUD、owner 关联、批量读取、关联计数

## 当前需要特别避免的过期说法

1. 不要再把当前总结主流程描述为 `event_summaries` 驱动
2. 不要再把 `EventStatus` 写成当前活跃接口的一部分
3. 不要再把 `TagProvider`、`SummaryProvider`、`FilesProvider` 说成“尚未实现”