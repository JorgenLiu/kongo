# Kongo 数据库设计文档

## 数据库概览

**数据库类型**: SQLite 3.x  
**数据库名**: `kongo.db`  
**字符集**: UTF-8  
**版本**: 1.0  

---

## 数据库ER图

```
┌──────────────────┐
│    contacts      │
├──────────────────┤
│ id (PK)          │
│ name             │
│ phone            │
│ email            │
│ address          │
│ notes            │
│ avatar           │
│ createdAt        │
│ updatedAt        │
└────────┬─────────┘
         │ 1:N
         │
    ┌────▼──────────┐
    │ contact_tags  │
    ├───────────────┤
    │ id (PK)       │
    │ contactId (FK)│
    │ tagId (FK)    │
    │ addedAt       │
    └────┬────┬────┘
         │    │
    N:M 1:N  N:1
         │    │
    ┌────▼────▼────┐
    │     tags      │
    ├───────────────┤
    │ id (PK)       │
    │ name          │
    │ color         │
    │ createdAt     │
    └───────────────┘

┌──────────────────┐
│    contacts      │
└────────┬─────────┘
         │ 1:N
         │
    ┌────▼────────────────┐
    │ contact_events       │
    ├──────────────────────┤
    │ id (PK)              │
    │ contactId (FK)       │
    │ eventTypeId (FK)     │
    │ date                 │
    │ reminderEnabled      │
    │ reminderDays         │
    │ notes                │
    │ createdAt            │
    │ updatedAt            │
    └────┬───────────┬────┘
         │           │
    N:M 1:N       N:1
         │           │
    ┌────▼─────┐ ┌──▼──────────────┐
    │  tags    │ │  event_types    │
    │(see above)│ ├──────────────────┤
    └──────────┘ │ id (PK)          │
                 │ name             │
                 │ icon             │
                 │ color            │
                 │ createdAt        │
                 └──────────────────┘
```

---

## 表结构详设

### 1. contacts（通讯人表）

**表名**: `contacts`  
**用途**: 存储所有通讯人的基本信息  
**索引**: 
- id (主键)
- name (用于搜索)

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

-- 创建索引以加速搜索
CREATE INDEX idx_contacts_name ON contacts(name);
CREATE INDEX idx_contacts_phone ON contacts(phone);
CREATE INDEX idx_contacts_email ON contacts(email);
CREATE INDEX idx_contacts_createdAt ON contacts(createdAt);
```

**字段说明**:

| 字段名 | 类型 | 长度 | 非空 | 说明 |
|--------|------|------|------|------|
| id | TEXT | - | ✓ | 主键，UUID格式 |
| name | TEXT | 255 | ✓ | 通讯人姓名 |
| phone | TEXT | 20 | ✗ | 电话号码 |
| email | TEXT | 255 | ✗ | 邮箱地址 |
| address | TEXT | 500 | ✗ | 联系地址 |
| notes | TEXT | 1000 | ✗ | 备注信息 |
| avatar | BLOB | - | ✗ | 头像图片（二进制） |
| createdAt | INTEGER | - | ✓ | 创建时间（毫秒时间戳） |
| updatedAt | INTEGER | - | ✓ | 更新时间（毫秒时间戳） |

**示例数据**:

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "name": "张三",
  "phone": "+86-13800000000",
  "email": "zhangsan@example.com",
  "address": "北京市朝阳区",
  "notes": "大学同学，经常联系",
  "avatar": null,
  "createdAt": 1709702400000,
  "updatedAt": 1709702400000
}
```

---

### 2. tags（标签表）

**表名**: `tags`  
**用途**: 存储所有标签信息  
**索引**: 
- id (主键)
- name (唯一约束，用于快速查找)

```sql
CREATE TABLE tags (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  color TEXT,
  createdAt INTEGER NOT NULL
);

-- 创建索引
CREATE INDEX idx_tags_name ON tags(name);
```

**字段说明**:

| 字段名 | 类型 | 长度 | 非空 | 说明 |
|--------|------|------|------|------|
| id | TEXT | - | ✓ | 主键，UUID格式 |
| name | TEXT | 50 | ✓ | 标签名称，唯一 |
| color | TEXT | 7 | ✗ | 标签颜色（十六进制#RRGGBB） |
| createdAt | INTEGER | - | ✓ | 创建时间（毫秒时间戳） |

**示例数据**:

```json
[
  {
    "id": "tag-001",
    "name": "家人",
    "color": "#FF5252",
    "createdAt": 1709702400000
  },
  {
    "id": "tag-002",
    "name": "同事",
    "color": "#42A5F5",
    "createdAt": 1709702400000
  },
  {
    "id": "tag-003",
    "name": "朋友",
    "color": "#66BB6A",
    "createdAt": 1709702400000
  }
]
```

---

### 3. contact_tags（通讯人-标签关联表）

**表名**: `contact_tags`  
**用途**: 实现通讯人与标签的多对多关系  
**索引**: 
- 主键
- 联合唯一约束(contactId, tagId)
- 外键索引

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

-- 创建索引
CREATE INDEX idx_contact_tags_contactId ON contact_tags(contactId);
CREATE INDEX idx_contact_tags_tagId ON contact_tags(tagId);
```

**字段说明**:

| 字段名 | 类型 | 长度 | 非空 | 说明 |
|--------|------|------|------|------|
| id | TEXT | - | ✓ | 主键，UUID格式 |
| contactId | TEXT | - | ✓ | 外键，关联contacts表 |
| tagId | TEXT | - | ✓ | 外键，关联tags表 |
| addedAt | INTEGER | - | ✓ | 添加时间（毫秒时间戳） |

**示例数据**:

```json
[
  {
    "id": "ct-001",
    "contactId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "tagId": "tag-001",
    "addedAt": 1709702400000
  },
  {
    "id": "ct-002",
    "contactId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "tagId": "tag-002",
    "addedAt": 1709702400000
  }
]
```

---

### 4. event_types（事件类型表）

**表名**: `event_types`  
**用途**: 定义可用的事件类型（生日、会面日期、结婚纪念日等）  
**索引**: 
- id (主键)
- name (唯一约束)

```sql
CREATE TABLE event_types (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  icon TEXT,
  color TEXT,
  createdAt INTEGER NOT NULL
);

-- 创建索引
CREATE INDEX idx_event_types_name ON event_types(name);
```

**字段说明**:

| 字段名 | 类型 | 长度 | 非空 | 说明 |
|--------|------|------|------|------|
| id | TEXT | - | ✓ | 主键，UUID格式 |
| name | TEXT | 50 | ✓ | 事件类型名称（唯一） |
| icon | TEXT | 100 | ✗ | 图标emoji或URL |
| color | TEXT | 7 | ✗ | 颜色（十六进制#RRGGBB） |
| createdAt | INTEGER | - | ✓ | 创建时间（毫秒时间戳） |

**预设事件类型**:

```json
[
  {
    "id": "evt-type-001",
    "name": "生日",
    "icon": "🎂",
    "color": "#FF5252",
    "createdAt": 1709702400000
  },
  {
    "id": "evt-type-002",
    "name": "会面日期",
    "icon": "📅",
    "color": "#42A5F5",
    "createdAt": 1709702400000
  },
  {
    "id": "evt-type-003",
    "name": "结婚纪念日",
    "icon": "💍",
    "color": "#EC407A",
    "createdAt": 1709702400000
  },
  {
    "id": "evt-type-004",
    "name": "工作纪念日",
    "icon": "💼",
    "color": "#AB47BC",
    "createdAt": 1709702400000
  }
]
```

---

### 5. contact_events（通讯人事件表）

**表名**: `contact_events`  
**用途**: 存储通讯人的具体事件信息（如张三的生日、李四的结婚纪念日等）  
**索引**: 
- 主键
- 外键
- 日期索引（用于查询即将发生的事件）

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

-- 创建索引
CREATE INDEX idx_contact_events_contactId ON contact_events(contactId);
CREATE INDEX idx_contact_events_eventTypeId ON contact_events(eventTypeId);
CREATE INDEX idx_contact_events_date ON contact_events(date);
```

**字段说明**:

| 字段名 | 类型 | 长度 | 非空 | 说明 |
|--------|------|------|------|------|
| id | TEXT | - | ✓ | 主键，UUID格式 |
| contactId | TEXT | - | ✓ | 外键，关联contacts表 |
| eventTypeId | TEXT | - | ✓ | 外键，关联event_types表 |
| date | TEXT | 10 | ✓ | 事件日期（YYYY-MM-DD格式） |
| reminderEnabled | INTEGER | 1 | ✗ | 是否启用提醒（0/1） |
| reminderDays | INTEGER | - | ✗ | 提前几天提醒（0-365） |
| notes | TEXT | 500 | ✗ | 事件备注 |
| createdAt | INTEGER | - | ✓ | 创建时间（毫秒时间戳） |
| updatedAt | INTEGER | - | ✓ | 更新时间（毫秒时间戳） |

**示例数据**:

```json
{
  "id": "evt-001",
  "contactId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "eventTypeId": "evt-type-001",
  "date": "1990-06-15",
  "reminderEnabled": 1,
  "reminderDays": 3,
  "notes": "送生日礼物",
  "createdAt": 1709702400000,
  "updatedAt": 1709702400000
}
```

---

## 查询SQL示例

### 1. 获取某个通讯人的所有信息

```sql
-- 获取基本信息
SELECT * FROM contacts WHERE id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

-- 获取标签
SELECT t.* FROM tags t
JOIN contact_tags ct ON t.id = ct.tagId
WHERE ct.contactId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

-- 获取事件
SELECT ce.*, et.name AS eventTypeName, et.icon, et.color
FROM contact_events ce
JOIN event_types et ON ce.eventTypeId = et.id
WHERE ce.contactId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
ORDER BY ce.date;
```

### 2. 按单个标签搜索通讯人

```sql
SELECT DISTINCT c.* FROM contacts c
JOIN contact_tags ct ON c.id = ct.contactId
WHERE ct.tagId = 'tag-001'
ORDER BY c.createdAt DESC;
```

### 3. 按多个标签搜索（OR模式）

```sql
SELECT DISTINCT c.* FROM contacts c
JOIN contact_tags ct ON c.id = ct.contactId
WHERE ct.tagId IN ('tag-001', 'tag-002')
ORDER BY c.createdAt DESC;
```

### 4. 按多个标签搜索（AND模式）

```sql
SELECT c.* FROM contacts c
WHERE c.id IN (
  SELECT ct.contactId FROM contact_tags ct
  WHERE ct.tagId IN ('tag-001', 'tag-002')
  GROUP BY ct.contactId
  HAVING COUNT(DISTINCT ct.tagId) = 2
)
ORDER BY c.createdAt DESC;
```

### 5. 全文搜索

```sql
SELECT * FROM contacts
WHERE name LIKE '%关键词%'
   OR phone LIKE '%关键词%'
   OR email LIKE '%关键词%'
   OR address LIKE '%关键词%'
   OR notes LIKE '%关键词%'
ORDER BY createdAt DESC;
```

### 6. 获取即将发生的事件（30天内）

```sql
SELECT ce.*, c.name AS contactName, et.name AS eventTypeName
FROM contact_events ce
JOIN contacts c ON ce.contactId = c.id
JOIN event_types et ON ce.eventTypeId = et.id
WHERE ce.date BETWEEN date('now') AND date('now', '+30 days')
ORDER BY ce.date;
```

### 7. 获取即将生日的人（本月）

```sql
SELECT c.*, ce.date
FROM contacts c
JOIN contact_events ce ON c.id = ce.contactId
JOIN event_types et ON ce.eventTypeId = et.id
WHERE et.name = '生日'
  AND strftime('%m', ce.date) = strftime('%m', 'now')
ORDER BY CAST(strftime('%d', ce.date) AS INTEGER);
```

---

## 数据库设计原则

### 1. 规范化（Normalization）
- **第一范式(1NF)**: 所有字段都是原子值
- **第二范式(2NF)**: 消除非键属性对主键的部分依赖
- **第三范式(3NF)**: 消除非键属性之间的传递依赖

### 2. 索引策略
- **主键索引**: 自动创建
- **外键索引**: 加速JOIN查询
- **搜索字段索引**: name, phone, email等常用搜索字段
- **日期索引**: 加速日期范围查询

### 3. 性能优化
- 合理设置字段长度
- 使用整数存储时间戳而非字符串
- 避免过度索引（影响写入性能）
- 定期分析表统计以优化查询计划

### 4. 数据完整性
- 使用外键约束保证关系完整性
- 使用NOT NULL和唯一约束避免重复
- 级联删除确保数据一致性

---

## 数据备份与恢复

### 备份策略

```dart
// 导出数据库为SQL文件
Future<void> backupDatabase(String backupPath) async {
  final db = await database;
  final sql = await db.query('sqlite_master');
  // 将SQL写入文件
}

// 导出为JSON格式
Future<void> exportToJson(String jsonPath) async {
  // 导出contacts, tags, contact_tags, event_types, contact_events
}
```

### 恢复策略

```dart
// 从备份恢复
Future<void> restoreDatabase(String backupPath) async {
  // 读取备份文件并执行SQL
}
```

---

## 数据库迁移指南

### 添加新表

```sql
-- 编写新表的CREATE语句
CREATE TABLE new_table (
  id TEXT PRIMARY KEY,
  ...
);

-- 在DatabaseService._onCreate或_onUpgrade中添加
```

### 修改表结构

SQLite不支持直接ALTER TABLE修改列，需要使用以下方式：

```dart
// 方法1：重命名旧表，创建新表，迁移数据
await db.execute('ALTER TABLE contacts RENAME TO contacts_old');
await db.execute('CREATE TABLE contacts (...)');
await db.execute('INSERT INTO contacts SELECT ... FROM contacts_old');
await db.execute('DROP TABLE contacts_old');

// 方法2：使用sqflite的批量操作
Batch batch = db.batch();
// 添加操作
batch.execute('...');
batch.execute('...');
await batch.commit();
```

---

## 版本历史

### v1.0 (2026-03-06)
- 初始数据库设计
- 5个核心表
- 基础功能支持

---

## 参考文档

- [SQLite官方文档](https://www.sqlite.org/docs.html)
- [sqflite包文档](https://pub.dev/packages/sqflite)
- [数据库设计最佳实践](https://www.postgresql.org/docs/current/ddl.html)

