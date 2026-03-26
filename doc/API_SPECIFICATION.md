# Kongo 内部接口规范

## 文档目的

本文档描述当前代码里真实存在、且应继续遵守的接口边界。

当前主分层：

```text
Screen -> Widget / Action -> Provider -> Read Service / Service -> Repository -> SQLite / File System
```

## 通用约束

### Screen

- 负责页面编排、导航与状态选择
- 不直接做多仓储聚合

### Provider

- 管理页面状态、异步流程、错误与初始化标记
- 写流程依赖 `Service`
- 读流程优先依赖 `ReadService`

### Service

- 封装业务规则、校验与写侧编排

### Read Service

- 只负责只读聚合
- 不承担 create / update / delete 规则

### Repository

- 只负责数据访问与批量查询
- 不承担业务语义

## 异常模型

当前统一异常定义在 `lib/exceptions/app_exception.dart`。

### 已实现异常类型

- `DatabaseException`
- `ValidationException`
- `BusinessException`
- `FileStorageException`
- `AiException`

### 返回约定

- 列表查询返回空列表，不返回 `null`
- 单对象查询通常抛异常，不返回空对象
- 创建 / 更新方法返回最终落库对象
- 只有明确允许“缺失即正常”的接口返回可空值，例如 `getSummaryByDate()`

## Service 契约

### ContactService

职责：联系人 CRUD、关键字搜索、按标签过滤、联系人视角读取事件与标签。

### TagService

职责：标签 CRUD 与联系人打标。

### EventService

职责：事件写侧规则、事件类型、参与人维护。

重要约束：

- 事件标题必填
- 事件至少保留一个参与人
- 当前不包含事件状态流转规则

### ContactMilestoneService

职责：联系人重要日期 CRUD 与查询。

当前接口形态：

```dart
abstract class ContactMilestoneService {
  Future<List<ContactMilestone>> getAllMilestones();
  Future<List<ContactMilestone>> getMilestones(String contactId);
  Future<ContactMilestone> getMilestone(String id);
  Future<ContactMilestone> createMilestone(String contactId, ContactMilestoneDraft draft);
  Future<ContactMilestone> updateMilestone(ContactMilestone milestone);
  Future<void> deleteMilestone(String id);
  Future<List<ContactMilestone>> getUpcomingMilestones({int days = 30});
}
```

规则：

- 自定义类型必须填写 `label`
- 创建前校验联系人存在性
- `isLunar` 当前可存储，但农历节点尚未进入日历展示

### SummaryService

职责：每日总结 CRUD、日期唯一约束、行动项提取。

规则：

- `todaySummary` 与 `tomorrowPlan` 至少填一项
- 每天只允许一条总结

### CalendarTimeNodeSettingsService

职责：时间节点类别开关读取与持久化。

当前接口形态：

```dart
abstract class CalendarTimeNodeSettingsService {
  Future<CalendarTimeNodeSettings> getSettings();
  Future<CalendarTimeNodeSettings> setKindEnabled(
    CalendarTimeNodeKind kind,
    bool enabled,
  );
}
```

规则：

- 当前设置持久化在 `app_preferences`
- 默认启用联系人重要日期、公共纪念日与营销节点
- 设置变更后，事件页时间节点读模型应按最新配置返回

### TodoService

职责：待办组与待办项写侧规则、层级约束与多关联维护。

当前接口形态：

```dart
abstract class TodoService {
  Future<TodoGroup> createGroup(TodoGroupDraft draft);
  Future<TodoGroup> updateGroup(TodoGroup group);
  Future<void> deleteGroup(String groupId);
  Future<TodoItem> createItem(String groupId, TodoItemDraft draft);
  Future<TodoItem> updateItem(
    TodoItem item, {
    List<String> contactIds = const [],
    List<String> eventIds = const [],
  });
  Future<void> deleteItem(String itemId);
  Future<TodoItem> setItemCompleted(String itemId, bool completed);
}
```

规则：

- 待办组名称必填
- 待办项标题必填
- 当前仅支持两层待办结构
- 子项必须与父项属于同一待办组
- 联系人与事件关联在写入前都要校验存在性

### AttachmentService

职责：附件落盘、元数据维护、owner 关联、打开、删除。

规则：

- 源文件必须存在
- 删除前要检查 owner 关联
- 当前 owner 类型是 `event` 与 `summary`

## Read Service 契约

### ContactReadService

职责：联系人详情页只读聚合。

读模型包含：

- 联系人本体
- 标签
- 事件
- 聚合附件
- 事件类型名称映射
- 联系人重要日期列表

### EventReadService

职责：事件列表与事件详情只读聚合。

当前接口形态：

```dart
abstract class EventReadService {
  Future<EventsListReadModel> getEventsList({String? contactId});
  Future<EventsListReadModel> searchEventsList({
    String? contactId,
    String? keyword,
    String? eventTypeId,
  });
  Future<EventDetailReadModel> getEventDetail(String eventId);
}
```

当前事件列表读模型：

```dart
class EventsListReadModel {
  final Contact? contact;
  final List<EventListItemReadModel> items;
  final List<CalendarTimeNodeReadModel> calendarTimeNodes;
}

class EventListItemReadModel {
  final Event event;
  final String? eventTypeName;
  final List<String> participantNames;
}

enum CalendarTimeNodeKind { contactMilestone, publicHoliday, marketingCampaign }

class CalendarTimeNodeReadModel {
  final String id;
  final CalendarTimeNodeKind kind;
  final String title;
  final String? subtitle;
  final String leadingText;
  final DateTime anchorDate;
  final String? linkedContactId;
  final bool isRecurring;
  final bool isLunar;
}
```

说明：

- `calendarTimeNodes` 当前包含联系人重要日期、公共纪念日与营销节点三类节点
- 当前尚未包含节气等更多来源
- 节点类别开关通过 `CalendarTimeNodeSettingsService` 进入主路径

### SummaryReadService

职责：每日总结列表 / 详情只读聚合。

### HomeReadService

职责：今日工作台只读聚合。

当前用于聚合：

- 今日事件
- 当日总结中的行动项
- 未来 30 天的重要日期

### TodoReadService

职责：待办组页面只读聚合。

当前用于聚合：

- 待办组列表与完成进度
- 选中待办组的一级项 / 子项树
- 子项关联的联系人与事件
- 待办编辑可选联系人 / 事件列表

## Provider 契约

### 基础设施

- `BaseProvider`：统一 `loading`、`initialized`、`error`、`execute()`
- `ProviderError`：将异常转换为展示层错误结构

### 已实现 Provider

- `ContactProvider`
- `ContactDetailProvider`
- `CalendarTimeNodeSettingsProvider`
- `TodoBoardProvider`
- `EventProvider`
- `EventsListProvider`
- `EventDetailProvider`
- `TagProvider`
- `SummaryProvider`
- `AttachmentProvider`
- `FilesProvider`
- `GlobalSearchProvider`

## Repository 契约

当前主 Repository：

- `AppPreferenceRepository`
- `ContactRepository`
- `TagRepository`
- `EventRepository`
- `SummaryRepository`
- `AttachmentRepository`
- `ContactMilestoneRepository`
- `TodoGroupRepository`
- `TodoItemRepository`

其中 `ContactMilestoneRepository` 当前职责包括：

- `getAll()`
- `getByContactId()`
- `getById()`
- `insert()`
- `update()`
- `delete()`
- `deleteByContactId()`
- `getUpcoming()`

## 当前尚不存在的正式契约

以下能力还没有稳定到可以写成正式接口承诺：

1. 外部节气 / 世界纪念日 / 营销节点源
