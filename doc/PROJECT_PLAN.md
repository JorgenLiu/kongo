# Kongo - 通讯录和日程管理App | 项目规划文档

## 项目概述

**应用名称**: Kongo（金刚）  
**描述**: 跨平台通讯录与日程管理应用  
**目标平台**: macOS、Windows、iOS（第一阶段从macOS开始）  
**技术栈**: Flutter + Dart + SQLite  
**目标版本**: v1.0

---

## 第一版需求分析

### 功能需求清单

#### 1. 通讯人管理
- [x] 创建通讯人
- [x] 编辑通讯人信息
- [x] 删除通讯人
- [x] 查看通讯人列表

#### 2. 标签系统
- [x] 为通讯人添加标签
- [x] 管理标签（创建、编辑、删除）
- [x] 单个标签查找
- [x] 多个标签组合查找（OR/AND逻辑）

#### 3. 时间节点管理
- [x] 创建时间节点（生日、会面日期、结婚纪念日等）
- [x] 编辑时间节点
- [x] 查看时间节点
- [x] 删除时间节点
- [x] 时间节点类型管理

#### 4. 数据持久化
- [x] SQLite本地存储
- [x] 数据备份与恢复（可选）

---

## 数据库设计

### ER图关系

```
Contact (通讯人)
    ├── id (PK)
    ├── name
    ├── phone
    ├── email
    ├── address
    ├── notes
    ├── avatar
    ├── createdAt
    ├── updatedAt
    └── (1:N) → ContactTag
         └── (N:M) → Tag

Tag (标签)
    ├── id (PK)
    ├── name
    ├── color
    ├── createdAt
    └── (1:N) → ContactTag

ContactTag (通讯人-标签关联)
    ├── id (PK)
    ├── contactId (FK)
    ├── tagId (FK)
    └── addedAt

EventType (事件类型)
    ├── id (PK)
    ├── name (生日、会面日期、结婚纪念日等)
    ├── icon
    └── color

ContactEvent (联系人时间节点)
    ├── id (PK)
    ├── contactId (FK)
    ├── eventTypeId (FK)
    ├── date
    ├── reminderEnabled
    ├── reminderDays (提前几天提醒)
    ├── notes
    ├── createdAt
    └── updatedAt
```

### 数据库表详设

#### 1. `contacts` 表
```sql
CREATE TABLE contacts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address TEXT,
  notes TEXT,
  avatar BLOB,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL
);
```

#### 2. `tags` 表
```sql
CREATE TABLE tags (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  color TEXT,
  createdAt INTEGER NOT NULL
);
```

#### 3. `contact_tags` 表（多对多关系）
```sql
CREATE TABLE contact_tags (
  id TEXT PRIMARY KEY,
  contactId TEXT NOT NULL,
  tagId TEXT NOT NULL,
  addedAt INTEGER NOT NULL,
  FOREIGN KEY (contactId) REFERENCES contacts(id) ON DELETE CASCADE,
  FOREIGN KEY (tagId) REFERENCES tags(id) ON DELETE CASCADE,
  UNIQUE(contactId, tagId)
);
```

#### 4. `event_types` 表
```sql
CREATE TABLE event_types (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  icon TEXT,
  color TEXT,
  createdAt INTEGER NOT NULL
);
```

#### 5. `contact_events` 表
```sql
CREATE TABLE contact_events (
  id TEXT PRIMARY KEY,
  contactId TEXT NOT NULL,
  eventTypeId TEXT NOT NULL,
  date TEXT NOT NULL,
  reminderEnabled INTEGER DEFAULT 0,
  reminderDays INTEGER DEFAULT 0,
  notes TEXT,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  FOREIGN KEY (contactId) REFERENCES contacts(id) ON DELETE CASCADE,
  FOREIGN KEY (eventTypeId) REFERENCES event_types(id)
);
```

---

## 项目结构规划

```
kongo/
├── lib/
│   ├── main.dart                          # 应用入口
│   ├── config/
│   │   ├── app_config.dart                # 应用配置
│   │   ├── app_theme.dart                 # 主题配置
│   │   └── constants.dart                 # 常量定义
│   │
│   ├── models/
│   │   ├── contact.dart                   # 通讯人数据模型
│   │   ├── tag.dart                       # 标签数据模型
│   │   ├── event_type.dart                # 事件类型数据模型
│   │   ├── contact_event.dart             # 联系人事件数据模型
│   │   └── database.dart                  # 数据库模型
│   │
│   ├── services/
│   │   ├── database_service.dart          # 数据库服务（初始化、迁移）
│   │   ├── contact_service.dart           # 通讯人业务逻辑
│   │   ├── tag_service.dart               # 标签业务逻辑
│   │   └── event_service.dart             # 事件业务逻辑
│   │
│   ├── repositories/
│   │   ├── contact_repository.dart        # 通讯人数据仓库
│   │   ├── tag_repository.dart            # 标签数据仓库
│   │   └── event_repository.dart          # 事件数据仓库
│   │
│   ├── providers/
│   │   ├── contact_provider.dart          # 通讯人状态管理（Provider）
│   │   ├── tag_provider.dart              # 标签状态管理
│   │   └── event_provider.dart            # 事件状态管理
│   │
│   ├── screens/
│   │   ├── home/
│   │   │   └── home_screen.dart           # 首页
│   │   ├── contacts/
│   │   │   ├── contacts_list_screen.dart  # 通讯人列表
│   │   │   ├── contact_detail_screen.dart # 通讯人详情
│   │   │   ├── contact_form_screen.dart   # 通讯人编辑表单
│   │   │   └── contact_search_screen.dart # 通讯人搜索
│   │   ├── tags/
│   │   │   ├── tags_screen.dart           # 标签管理
│   │   │   └── tag_form_screen.dart       # 标签编辑
│   │   ├── events/
│   │   │   ├── events_screen.dart         # 事件列表
│   │   │   └── event_form_screen.dart     # 事件编辑
│   │   └── settings/
│   │       └── settings_screen.dart       # 设置页面
│   │
│   ├── widgets/
│   │   ├── common/
│   │   │   ├── custom_app_bar.dart        # 自定义应用栏
│   │   │   ├── custom_button.dart         # 自定义按钮
│   │   │   └── empty_state.dart           # 空状态提示
│   │   ├── contact/
│   │   │   ├── contact_card.dart          # 通讯人卡片
│   │   │   ├── contact_item.dart          # 通讯人列表项
│   │   │   └── tag_chip.dart              # 标签chip
│   │   └── event/
│   │       ├── event_item.dart            # 事件列表项
│   │       └── event_timeline.dart        # 事件时间线
│   │
│   ├── utils/
│   │   ├── date_utils.dart                # 日期处理工具
│   │   ├── string_utils.dart              # 字符串处理工具
│   │   ├── uuid_utils.dart                # UUID生成工具
│   │   └── logger.dart                    # 日志工具
│   │
│   └── exceptions/
│       ├── app_exception.dart             # 应用异常基类
│       ├── database_exception.dart        # 数据库异常
│       └── validation_exception.dart      # 验证异常
│
├── test/                                  # 单元测试目录
│   ├── models/
│   ├── services/
│   ├── repositories/
│   └── widgets/
│
├── pubspec.yaml                           # 项目配置文件
├── README.md                              # 项目说明
├── PROJECT_PLAN.md                        # 项目规划（本文件）
└── DEVELOPMENT_GUIDE.md                   # 开发指南
```

---

## 技术栈详解

### 核心依赖

| 包名 | 版本 | 用途 |
|------|------|------|
| `flutter` | latest | UI框架 |
| `dart` | latest | 编程语言 |
| `provider` | ^6.0.0 | 状态管理 |
| `sqflite` | ^2.3.0 | SQLite数据库 |
| `path_provider` | ^2.0.0 | 文件系统路径 |
| `uuid` | ^4.0.0 | UUID生成 |
| `intl` | ^0.19.0 | 国际化与日期格式化 |
| `flutter_colorpicker` | ^1.0.0 | 颜色选择器 |
| `cached_network_image` | ^3.0.0 | 图片缓存 |
| `shared_preferences` | ^2.0.0 | 本地偏好设置 |

### 开发工具依赖

| 包名 | 用途 |
|------|------|
| `flutter_test` | 单元测试 |
| `mockito` | Mock框架 |
| `flutter_lints` | Lint规则 |

---

## 开发阶段规划

### Phase 1: 项目初始化与基础架构 (第1-2周)
- [ ] 创建Flutter项目
- [ ] 配置项目结构
- [ ] 设置依赖包
- [ ] 实现数据库初始化
- [ ] 设计App主题与配色

### Phase 2: 数据模型与数据库 (第2-3周)
- [ ] 设计和实现数据模型
- [ ] 实现SQLite数据库操作
- [ ] 创建Repository层
- [ ] 编写数据库迁移脚本
- [ ] 单元测试覆盖

### Phase 3: 核心业务逻辑层 (第3-4周)
- [ ] 实现Service层
- [ ] 实现Provider状态管理
- [ ] 业务逻辑单元测试
- [ ] 性能优化

### Phase 4: UI开发 (第4-6周)
- [ ] 通讯人列表页面
- [ ] 通讯人详情页面
- [ ] 通讯人编辑/创建页面
- [ ] 标签管理页面
- [ ] 事件管理页面
- [ ] 搜索与过滤页面
- [ ] 首页和导航

### Phase 5: 功能集成与测试 (第6-7周)
- [ ] 端到端测试
- [ ] 用户体验测试
- [ ] Bug修复
- [ ] 性能优化

### Phase 6: macOS适配与发布 (第7-8周)
- [ ] macOS平台特性适配
- [ ] macOS Build配置
- [ ] 打包与签名
- [ ] 应用分发准备

---

## API接口设计

### ContactService
```dart
// 获取所有通讯人
Future<List<Contact>> getContacts();

// 获取单个通讯人
Future<Contact?> getContact(String id);

// 创建通讯人
Future<Contact> createContact(Contact contact);

// 更新通讯人
Future<Contact> updateContact(Contact contact);

// 删除通讯人
Future<void> deleteContact(String id);

// 按标签搜索通讯人
Future<List<Contact>> searchByTags(List<String> tagIds, {SearchMode mode = SearchMode.or});

// 全文搜索
Future<List<Contact>> searchByKeyword(String keyword);
```

### TagService
```dart
// 获取所有标签
Future<List<Tag>> getTags();

// 创建标签
Future<Tag> createTag(Tag tag);

// 更新标签
Future<Tag> updateTag(Tag tag);

// 删除标签
Future<void> deleteTag(String id);

// 为通讯人添加标签
Future<void> addTagToContact(String contactId, String tagId);

// 从通讯人移除标签
Future<void> removeTagFromContact(String contactId, String tagId);

// 获取通讯人的所有标签
Future<List<Tag>> getContactTags(String contactId);
```

### EventService
```dart
// 获取所有事件类型
Future<List<EventType>> getEventTypes();

// 创建事件类型
Future<EventType> createEventType(EventType eventType);

// 获取通讯人的所有事件
Future<List<ContactEvent>> getContactEvents(String contactId);

// 创建事件
Future<ContactEvent> createEvent(ContactEvent event);

// 更新事件
Future<ContactEvent> updateEvent(ContactEvent event);

// 删除事件
Future<void> deleteEvent(String id);

// 获取即将发生的事件
Future<List<ContactEvent>> getUpcomingEvents({int days = 30});
```

---

## UI设计规范

### 色彩方案
- **Primary Color**: #2196F3 (蓝色)
- **Secondary Color**: #03DAC6 (青色)
- **Background**: #FFFFFF / #121212 (深色模式)
- **Surface**: #F5F5F5 / #1E1E1E (深色模式)
- **Error**: #B00020 (红色)
- **Success**: #4CAF50 (绿色)

### 字体规范
- **标题大字**: 32sp, Bold
- **标题中字**: 24sp, Bold
- **标题小字**: 20sp, Bold
- **正文大**: 16sp, Regular
- **正文小**: 14sp, Regular
- **标注**: 12sp, Regular

### 间距规范
- **超小**: 4dp
- **小**: 8dp
- **中**: 16dp
- **大**: 24dp
- **超大**: 32dp

---

## 通讯人信息字段设计

### 基本信息
- 姓名 *（必填）
- 电话号码
- 邮箱
- 地址
- 头像
- 备注

### 扩展信息
- 标签（多个）
- 时间节点（多个）

---

## 搜索与过滤功能

### 搜索模式

#### 1. 全文搜索
- 搜索范围：姓名、电话、邮箱、备注
- 支持模糊匹配

#### 2. 标签搜索
- 单个标签搜索
- 多个标签搜索
  - **OR模式**: 包含任意一个标签的通讯人
  - **AND模式**: 同时包含所有标签的通讯人

#### 3. 组合搜索
- 关键字 + 标签组合

---

## 提醒功能初步设计

### 提醒类型
1. **本地通知**（第一版实现）
   - 在特定日期提醒用户
   - 支持提前几天提醒

2. **日历同步**（第二版）
   - 与系统日历同步
   - 与第三方日历服务集成

---

## 性能优化策略

1. **数据库查询优化**
   - 为常用查询字段建立索引
   - 使用合适的查询语句避免N+1问题
   - 分页加载列表数据

2. **UI渲染优化**
   - 使用const constructor
   - 合理拆分Widget，避免不必要重构
   - ListView使用builder模式

3. **内存管理**
   - 及时销毁不使用的Provider
   - 避免内存泄漏

4. **数据缓存**
   - 缓存频繁查询的数据
   - 合理设置缓存失效策略

---

## 测试计划

### 单元测试
- 数据模型测试
- Service层业务逻辑测试
- Repository层数据操作测试
- Utility函数测试

### Widget测试
- 自定义Widget测试
- 页面交互测试

### 集成测试
- 端到端用户流程测试
- 数据流测试

### 测试覆盖率目标
- 总体覆盖率: ≥80%
- Service层: ≥90%
- Repository层: ≥85%

---

## 已知限制与未来计划

### 第一版限制
- [ ] 不支持数据云同步
- [ ] 不支持多设备同步
- [ ] 不支持数据加密
- [ ] 不支持分享功能

### 第二版计划
- [ ] 数据导入/导出（CSV、vCard）
- [ ] 云备份与同步
- [ ] 日历集成
- [ ] 提醒通知完善
- [ ] 分享联系人名片

### 第三版计划
- [ ] 端到端加密
- [ ] 多人协作
- [ ] CRM功能扩展
- [ ] 插件系统

---

## 开发建议

### 代码质量
1. 遵循Dart风格指南
2. 使用分析工具检查代码质量
3. 进行代码审查
4. 编写清晰的注释和文档

### 版本控制
1. 使用Git进行版本管理
2. 遵循Commit消息约定
3. 主分支保持可发布状态
4. 使用feature分支开发新功能

### 文档维护
1. 保持README最新
2. 更新API文档
3. 记录关键决策
4. 维护更新日志

---

## 打包与发布

### macOS打包
```bash
flutter build macos --release
```

### Windows打包
```bash
flutter build windows --release
```

### iOS打包
```bash
flutter build ios --release
```

---

## 参考资源

- [Flutter官方文档](https://flutter.dev/docs)
- [Dart官方文档](https://dart.dev/guides)
- [SQLite官方文档](https://www.sqlite.org/)
- [Provider状态管理](https://pub.dev/packages/provider)
- [sqflite数据库包](https://pub.dev/packages/sqflite)

---

**文档更新日期**: 2026年3月6日  
**版本**: v1.0  
**作者**: 开发团队
