# Kongo API 接口规范

## API架构概述

本文档定义了应用内部API接口规范，用于Service层、Repository层和UI层之间的通信。

---

## 通用规范

### 错误处理

#### 异常分类

```dart
// 基础异常类
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final Exception? originalException;

  AppException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() => message;
}

// 数据库异常
class DatabaseException extends AppException {
  DatabaseException({
    required String message,
    String? code,
    Exception? originalException,
  }) : super(
    message: message,
    code: code,
    originalException: originalException,
  );
}

// 验证异常
class ValidationException extends AppException {
  ValidationException({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

// 业务逻辑异常
class BusinessException extends AppException {
  BusinessException({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}
```

### 响应类型

所有异步方法都应该返回Future或Stream，不应返回nullable类型，而是通过异常处理。

```dart
// ✓ 正确做法
Future<Contact> getContact(String id);
Future<List<Contact>> getContacts();

// ✗ 错误做法
Future<Contact?> getContact(String id);  // 避免使用nullable Future
```

---

## ContactService API

### 概述
处理通讯人相关的业务逻辑。

### 方法签名

#### 1. 获取所有通讯人

```dart
/// 获取所有通讯人
/// 
/// 返回按创建时间降序排列的通讯人列表。
/// 
/// 返回值：
/// - 通讯人列表（若为空则返回空列表）
/// 
/// 异常：
/// - [DatabaseException] 如果数据库操作失败
Future<List<Contact>> getContacts();
```

**示例**:
```dart
try {
  final contacts = await contactService.getContacts();
  print('获取${contacts.length}个通讯人');
} on DatabaseException catch (e) {
  print('获取通讯人失败: ${e.message}');
}
```

---

#### 2. 获取单个通讯人

```dart
/// 获取指定ID的通讯人
/// 
/// 参数：
/// - [id] 通讯人ID
/// 
/// 返回值：
/// - 通讯人对象
/// 
/// 异常：
/// - [DatabaseException] 如果数据库操作失败或通讯人不存在
Future<Contact> getContact(String id);
```

**示例**:
```dart
try {
  final contact = await contactService.getContact('abc123');
  print('${contact.name} - ${contact.phone}');
} on DatabaseException catch (e) {
  print('获取通讯人失败: ${e.message}');
}
```

---

#### 3. 创建通讯人

```dart
/// 创建新的通讯人
/// 
/// 参数：
/// - [contact] 待创建的通讯人对象
///   注意：id、createdAt、updatedAt字段将被自动填充
/// 
/// 返回值：
/// - 创建成功后的通讯人对象（包含自动生成的id）
/// 
/// 异常：
/// - [ValidationException] 如果输入数据不合法
/// - [DatabaseException] 如果数据库操作失败
/// 
/// 业务规则：
/// - name 字段必填
/// - phone 和 email 可选但应符合格式要求
Future<Contact> createContact(Contact contact);
```

**示例**:
```dart
try {
  final newContact = Contact(
    id: '', // 将被忽略
    name: '张三',
    phone: '+86-13800000000',
    email: 'zhangsan@example.com',
    createdAt: DateTime.now(), // 将被覆盖
    updatedAt: DateTime.now(), // 将被覆盖
  );
  
  final created = await contactService.createContact(newContact);
  print('创建成功，ID: ${created.id}');
} on ValidationException catch (e) {
  print('输入数据不合法: ${e.message}');
}
```

---

#### 4. 更新通讯人

```dart
/// 更新现有通讯人信息
/// 
/// 参数：
/// - [contact] 更新后的通讯人对象
///   注意：id 必须存在，updatedAt 将被自动更新
/// 
/// 返回值：
/// - 更新成功后的通讯人对象
/// 
/// 异常：
/// - [ValidationException] 如果输入数据不合法
/// - [DatabaseException] 如果通讯人不存在或数据库操作失败
/// 
/// 业务规则：
/// - id 字段必须存在
/// - 只更新提供的字段值
Future<Contact> updateContact(Contact contact);
```

**示例**:
```dart
try {
  final updated = contact.copyWith(
    phone: '+86-13900000000',
  );
  
  final result = await contactService.updateContact(updated);
  print('更新成功');
} on DatabaseException catch (e) {
  print('更新失败: ${e.message}');
}
```

---

#### 5. 删除通讯人

```dart
/// 删除指定通讯人及其所有关联数据
/// 
/// 参数：
/// - [id] 待删除通讯人的ID
/// 
/// 异常：
/// - [DatabaseException] 如果通讯人不存在或数据库操作失败
/// 
/// 副作用：
/// - 删除该通讯人的所有标签关联
/// - 删除该通讯人的所有事件记录
Future<void> deleteContact(String id);
```

**示例**:
```dart
try {
  await contactService.deleteContact('abc123');
  print('删除成功');
} on DatabaseException catch (e) {
  print('删除失败: ${e.message}');
}
```

---

#### 6. 按关键词搜索

```dart
/// 全文搜索通讯人
/// 
/// 参数：
/// - [keyword] 搜索关键词
///   搜索范围：name、phone、email、address、notes
/// 
/// 返回值：
/// - 匹配的通讯人列表（按相关度排序）
/// 
/// 异常：
/// - [DatabaseException] 如果数据库操作失败
/// 
/// 搜索特性：
/// - 不区分大小写
/// - 支持模糊匹配（SQL LIKE）
/// - 空关键词返回所有通讯人
Future<List<Contact>> searchByKeyword(String keyword);
```

**示例**:
```dart
final results = await contactService.searchByKeyword('张三');
print('搜索到${results.length}个结果');
```

---

#### 7. 按标签搜索

```dart
/// 按标签搜索通讯人
/// 
/// 参数：
/// - [tagIds] 标签ID列表
/// - [mode] 搜索模式（OR 或 AND），默认为OR
///   - SearchMode.or: 返回包含任意一个标签的通讯人
///   - SearchMode.and: 返回同时包含所有标签的通讯人
/// 
/// 返回值：
/// - 符合条件的通讯人列表
/// 
/// 异常：
/// - [DatabaseException] 如果数据库操作失败
/// - [ValidationException] 如果tagIds为空
/// 
/// 示例：
/// - 搜索标签为['family', 'close_friend']的联系人
///   OR模式: 返回有family标签或close_friend标签的人
///   AND模式: 返回同时有两个标签的人
Future<List<Contact>> searchByTags(
  List<String> tagIds, {
  SearchMode mode = SearchMode.or,
});

enum SearchMode { or, and }
```

**示例**:
```dart
// OR搜索：包含任意标签
final results1 = await contactService.searchByTags(
  ['tag-001', 'tag-002'],
  mode: SearchMode.or,
);
print('搜索到${results1.length}个结果');

// AND搜索：同时包含所有标签
final results2 = await contactService.searchByTags(
  ['tag-001', 'tag-002'],
  mode: SearchMode.and,
);
print('搜索到${results2.length}个结果');
```

---

#### 8. 组合搜索

```dart
/// 组合搜索（关键词 + 标签）
/// 
/// 参数：
/// - [keyword] 搜索关键词（可选）
/// - [tagIds] 标签ID列表（可选）
/// - [tagMode] 标签搜索模式（OR 或 AND）
/// 
/// 返回值：
/// - 同时满足关键词和标签条件的通讯人列表
/// 
/// 异常：
/// - [DatabaseException] 如果数据库操作失败
/// 
/// 逻辑：
/// - 如果只提供keyword：按关键词搜索
/// - 如果只提供tagIds：按标签搜索
/// - 如果两者都提供：返回同时满足条件的结果（AND逻辑）
Future<List<Contact>> combinedSearch({
  String? keyword,
  List<String>? tagIds,
  SearchMode tagMode = SearchMode.or,
});
```

**示例**:
```dart
final results = await contactService.combinedSearch(
  keyword: '张三',
  tagIds: ['tag-001'],
  tagMode: SearchMode.or,
);
```

---

## TagService API

### 概述
处理标签相关的业务逻辑。

### 方法签名

#### 1. 获取所有标签

```dart
/// 获取所有标签
/// 
/// 返回值：
/// - 标签列表（按创建时间升序）
/// 
/// 异常：
/// - [DatabaseException] 如果数据库操作失败
Future<List<Tag>> getTags();
```

---

#### 2. 创建标签

```dart
/// 创建新标签
/// 
/// 参数：
/// - [tag] 待创建的标签对象
/// 
/// 返回值：
/// - 创建成功的标签对象（包含生成的id）
/// 
/// 异常：
/// - [ValidationException] 如果标签名称为空或重复
/// - [DatabaseException] 如果数据库操作失败
/// 
/// 业务规则：
/// - 标签名称必填且唯一
/// - 颜色为可选（默认随机颜色）
Future<Tag> createTag(Tag tag);
```

---

#### 3. 更新标签

```dart
/// 更新标签信息
/// 
/// 参数：
/// - [tag] 更新后的标签对象
/// 
/// 返回值：
/// - 更新后的标签对象
/// 
/// 异常：
/// - [ValidationException] 如果标签名称与其他标签重复
/// - [DatabaseException] 如果标签不存在或操作失败
Future<Tag> updateTag(Tag tag);
```

---

#### 4. 删除标签

```dart
/// 删除标签
/// 
/// 参数：
/// - [id] 待删除标签的ID
/// 
/// 异常：
/// - [DatabaseException] 如果标签不存在或操作失败
/// 
/// 副作用：
/// - 删除所有使用该标签的通讯人关联
Future<void> deleteTag(String id);
```

---

#### 5. 为通讯人添加标签

```dart
/// 为通讯人添加标签
/// 
/// 参数：
/// - [contactId] 通讯人ID
/// - [tagId] 标签ID
/// 
/// 异常：
/// - [DatabaseException] 如果数据库操作失败
/// - [ValidationException] 如果该标签已添加给该通讯人
/// 
/// 业务规则：
/// - 同一个标签不能添加两次
Future<void> addTagToContact(String contactId, String tagId);
```

---

#### 6. 从通讯人移除标签

```dart
/// 从通讯人移除标签
/// 
/// 参数：
/// - [contactId] 通讯人ID
/// - [tagId] 标签ID
/// 
/// 异常：
/// - [DatabaseException] 如果操作失败
Future<void> removeTagFromContact(String contactId, String tagId);
```

---

#### 7. 获取通讯人的所有标签

```dart
/// 获取某个通讯人拥有的所有标签
/// 
/// 参数：
/// - [contactId] 通讯人ID
/// 
/// 返回值：
/// - 标签列表
/// 
/// 异常：
/// - [DatabaseException] 如果数据库操作失败
Future<List<Tag>> getContactTags(String contactId);
```

---

#### 8. 获取使用某标签的通讯人数量

```dart
/// 获取使用某标签的通讯人数量
/// 
/// 参数：
/// - [tagId] 标签ID
/// 
/// 返回值：
/// - 使用该标签的通讯人数量
/// 
/// 异常：
/// - [DatabaseException] 如果数据库操作失败
Future<int> getContactCountByTag(String tagId);
```

---

## EventService API

### 概述
处理事件和事件类型相关的业务逻辑。

### 方法签名

#### 1. 获取所有事件类型

```dart
/// 获取所有预设的事件类型
/// 
/// 返回值：
/// - 事件类型列表
/// 
/// 异常：
/// - [DatabaseException] 如果数据库操作失败
Future<List<EventType>> getEventTypes();
```

---

#### 2. 创建事件类型

```dart
/// 创建新的事件类型
/// 
/// 参数：
/// - [eventType] 事件类型对象
/// 
/// 返回值：
/// - 创建成功的事件类型
/// 
/// 异常：
/// - [ValidationException] 如果事件类型名称重复或为空
/// - [DatabaseException] 如果数据库操作失败
Future<EventType> createEventType(EventType eventType);
```

---

#### 3. 获取通讯人的所有事件

```dart
/// 获取某个通讯人的所有事件
/// 
/// 参数：
/// - [contactId] 通讯人ID
/// 
/// 返回值：
/// - 事件列表（按日期升序）
/// 
/// 异常：
/// - [DatabaseException] 如果数据库操作失败
Future<List<ContactEvent>> getContactEvents(String contactId);
```

---

#### 4. 创建事件

```dart
/// 为通讯人创建新的时间节点事件
/// 
/// 参数：
/// - [event] 事件对象
/// 
/// 返回值：
/// - 创建成功的事件对象
/// 
/// 异常：
/// - [ValidationException] 如果输入数据不合法
/// - [DatabaseException] 如果数据库操作失败
/// 
/// 业务规则：
/// - date 字段格式必须为 YYYY-MM-DD
/// - reminderDays 范围 0-365
/// - 同一联系人同一类型只能有一个事件
Future<ContactEvent> createEvent(ContactEvent event);
```

---

#### 5. 更新事件

```dart
/// 更新事件信息
/// 
/// 参数：
/// - [event] 更新后的事件对象
/// 
/// 返回值：
/// - 更新后的事件对象
/// 
/// 异常：
/// - [ValidationException] 如果输入数据不合法
/// - [DatabaseException] 如果事件不存在或操作失败
Future<ContactEvent> updateEvent(ContactEvent event);
```

---

#### 6. 删除事件

```dart
/// 删除事件
/// 
/// 参数：
/// - [id] 事件ID
/// 
/// 异常：
/// - [DatabaseException] 如果事件不存在或操作失败
Future<void> deleteEvent(String id);
```

---

#### 7. 获取即将发生的事件

```dart
/// 获取指定天数内即将发生的事件
/// 
/// 参数：
/// - [days] 天数范围（默认30天）
/// 
/// 返回值：
/// - 按日期升序的事件列表及其关联的通讯人信息
/// 
/// 异常：
/// - [DatabaseException] 如果数据库操作失败
/// 
/// 说明：
/// - 仅返回启用提醒的事件
/// - 包含今天的事件
Future<List<UpcomingEvent>> getUpcomingEvents({int days = 30});

class UpcomingEvent {
  final ContactEvent event;
  final Contact contact;
  final EventType eventType;
  final int daysUntil;
  
  UpcomingEvent({
    required this.event,
    required this.contact,
    required this.eventType,
    required this.daysUntil,
  });
}
```

---

#### 8. 获取本月即将生日的人

```dart
/// 获取本月即将生日的通讯人
/// 
/// 返回值：
/// - 本月即将生日的通讯人列表（按生日日期升序）
/// 
/// 异常：
/// - [DatabaseException] 如果数据库操作失败
Future<List<Contact>> getBirthdaysThisMonth();
```

---

#### 9. 获取已过期的未提醒事件

```dart
/// 获取已过期但尚未处理的事件
/// 
/// 返回值：
/// - 已过期事件列表
/// 
/// 异常：
/// - [DatabaseException] 如果数据库操作失败
/// 
/// 用途：
/// - 用于提醒补偿逻辑
Future<List<ContactEvent>> getExpiredUnremindedEvents();
```

---

## DatabaseService API

### 概述
处理数据库初始化、迁移和底层操作。

### 方法签名

#### 1. 获取数据库实例

```dart
/// 获取单例数据库实例
/// 
/// 首次调用会初始化数据库，后续调用返回缓存的实例
/// 
/// 返回值：
/// - SQLite Database 实例
/// 
/// 异常：
/// - [DatabaseException] 如果初始化失败
Future<Database> get database;
```

---

#### 2. 初始化数据库

```dart
/// 初始化数据库（内部调用）
/// 
/// 创建数据库文件并执行初始化SQL
/// 
/// 异常：
/// - [DatabaseException] 如果操作失败
Future<Database> _initDatabase();
```

---

#### 3. 关闭数据库

```dart
/// 关闭数据库连接
/// 
/// 异常：
/// - [DatabaseException] 如果操作失败
Future<void> closeDatabase();
```

---

## 状态管理 (Provider) API

### ContactProvider

```dart
class ContactProvider extends ChangeNotifier {
  // 状态
  List<Contact> get contacts;
  bool get loading;
  String? get error;
  Contact? get currentContact;
  
  // 操作方法
  Future<void> loadContacts();
  Future<void> createContact(Contact contact);
  Future<void> updateContact(Contact contact);
  Future<void> deleteContact(String id);
  Future<void> searchByKeyword(String keyword);
  Future<void> searchByTags(List<String> tagIds, SearchMode mode);
  void setCurrentContact(Contact contact);
  void clearError();
}
```

### TagProvider

```dart
class TagProvider extends ChangeNotifier {
  List<Tag> get tags;
  bool get loading;
  String? get error;
  
  Future<void> loadTags();
  Future<void> createTag(Tag tag);
  Future<void> updateTag(Tag tag);
  Future<void> deleteTag(String id);
}
```

### EventProvider

```dart
class EventProvider extends ChangeNotifier {
  List<EventType> get eventTypes;
  List<ContactEvent> get events;
  bool get loading;
  String? get error;
  
  Future<void> loadEventTypes();
  Future<void> loadEvents(String contactId);
  Future<void> createEvent(ContactEvent event);
  Future<void> updateEvent(ContactEvent event);
  Future<void> deleteEvent(String id);
  Future<void> loadUpcomingEvents();
}
```

---

## 接口使用示例

### 完整使用流程示例

```dart
// 1. 初始化服务
final databaseService = DatabaseService();
final contactRepository = ContactRepository(databaseService);
final contactService = ContactService(contactRepository);

// 2. 创建通讯人
final newContact = await contactService.createContact(
  Contact(
    id: '',
    name: '李四',
    phone: '+86-13900000000',
    email: 'lisi@example.com',
    address: '上海市浦东新区',
    notes: '工作同事',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
);

// 3. 添加标签
await tagService.addTagToContact(newContact.id, 'tag-001');

// 4. 创建事件
final event = await eventService.createEvent(
  ContactEvent(
    id: '',
    contactId: newContact.id,
    eventTypeId: 'evt-type-001',
    date: '1985-06-15',
    reminderEnabled: true,
    reminderDays: 3,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
);

// 5. 查询
final upcoming = await eventService.getUpcomingEvents(days: 30);
final tagged = await contactService.searchByTags(
  ['tag-001'],
  mode: SearchMode.or,
);
```

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0 | 2026-03-06 | 初始版本 |

---

**最后更新**: 2026年3月6日

