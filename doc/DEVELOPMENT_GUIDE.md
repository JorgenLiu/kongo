# Kongo 开发指南

## 环境设置

### 系统要求
- macOS 11.0 或更高版本
- Xcode 13.0 或更高版本
- Flutter 3.0 或更高版本
- Dart 2.18 或更高版本

### 安装步骤

#### 1. 安装Flutter SDK
```bash
# 使用官方安装指南或Homebrew
brew install --cask flutter

# 验证安装
flutter --version
```

#### 2. 设置开发环境
```bash
# 获取项目依赖
flutter pub get

# 检查环境
flutter doctor
```

#### 3. 配置IDE
推荐使用VS Code或Android Studio
- 安装Flutter扩展
- 安装Dart扩展

---

## 项目初始化步骤

### 第1步：创建Flutter项目

```bash
cd /Users/geliu/dev/kongo
flutter create --org com.kongo kongo
cd kongo
```

### 第2步：配置pubspec.yaml

主要依赖包括：
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  sqflite: ^2.3.0
  path_provider: ^2.0.0
  uuid: ^4.0.0
  intl: ^0.19.0
```

### 第3步：创建项目文件夹结构

按照PROJECT_PLAN.md中的目录结构创建对应文件夹

### 第4步：初始化Git

```bash
git init
git add .
git commit -m "Initial commit: Flutter project setup"
```

---

## 编码规范

### 命名规范

#### 文件名
- 使用snake_case: `contact_service.dart`
- 一个文件只定义一个主要类

#### 类名
- 使用PascalCase: `class ContactService`
- 枚举: `enum SearchMode`
- 常量类: `class Constants`

#### 变量和方法
- 使用camelCase: `var userName`, `void fetchContacts()`
- 常量: `static const String appName = 'Kongo'`

#### 私有成员
- 前缀 `_`: `var _privateVar`, `void _privateMethod()`

### 代码风格

#### import顺序
```dart
// Dart标准库
import 'dart:async';
import 'dart:convert';

// Flutter SDK
import 'package:flutter/material.dart';

// 第三方包
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

// 本项目
import 'models/contact.dart';
import 'services/contact_service.dart';
```

#### 代码格式
```bash
# 使用dartfmt格式化代码
dart format lib/

# 使用dartanalyzer检查代码
dart analyze

# 在pubspec.yaml的dev_dependencies中添加flutter_lints
# 然后运行：
flutter analyze
```

### 注释规范

#### 文档注释
```dart
/// 获取所有通讯人
/// 
/// 返回按创建时间排序的通讯人列表。
/// 
/// 抛出异常：
/// - [DatabaseException] 如果数据库操作失败
Future<List<Contact>> getContacts() async {
  // ...
}
```

#### 代码注释
```dart
// 计算即将发生的事件
if (eventDate.isBefore(today.add(Duration(days: 30)))) {
  upcomingEvents.add(event);
}
```

---

## 架构设计详解

### 分层架构

```
┌─────────────────────────────────────┐
│          UI Layer (Screens)          │
│         (用户交互界面)               │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│       Widget Layer (Widgets)         │
│         (UI组件库)                  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│     Provider Layer (状态管理)        │
│      (应用状态与业务逻辑)            │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│     Service Layer (业务逻辑)         │
│    (业务规则与算法实现)              │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Repository Layer (数据访问)        │
│      (CRUD操作封装)                 │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│    Database Layer (SQLite)           │
│       (数据持久化)                   │
└─────────────────────────────────────┘
```

### 数据流向

```
User Interaction (用户交互)
        ↓
    Screen (页面)
        ↓
  Provider (状态管理)
        ↓
   Service (业务逻辑)
        ↓
Repository (数据访问)
        ↓
 Database (数据库)
```

---

## 关键开发步骤

### Step 1: 数据模型开发

创建 `lib/models/contact.dart`:
```dart
class Contact {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final List<int>? avatar;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contact({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.avatar,
    required this.createdAt,
    required this.updatedAt,
  });

  // fromMap和toMap用于数据库序列化
  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      notes: map['notes'],
      avatar: map['avatar'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'avatar': avatar,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // copyWith用于创建副本
  Contact copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    List<int>? avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

### Step 2: 数据库初始化

创建 `lib/services/database_service.dart`:
```dart
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kongo.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 创建所有表
    await db.execute(_sqlCreateContacts);
    await db.execute(_sqlCreateTags);
    await db.execute(_sqlCreateContactTags);
    await db.execute(_sqlCreateEventTypes);
    await db.execute(_sqlCreateContactEvents);
    
    // 初始化默认事件类型
    await _initDefaultEventTypes(db);
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // 处理数据库升级迁移逻辑
  }

  // SQL语句定义
  static const String _sqlCreateContacts = '''
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
    )
  ''';

  // ... 其他表的SQL语句
}
```

### Step 3: Repository层开发

创建 `lib/repositories/contact_repository.dart`:
```dart
class ContactRepository {
  final DatabaseService _dbService;

  ContactRepository(this._dbService);

  Future<List<Contact>> getAll() async {
    final db = await _dbService.database;
    final maps = await db.query('contacts');
    return maps.map((map) => Contact.fromMap(map)).toList();
  }

  Future<Contact?> getById(String id) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Contact.fromMap(maps.first);
  }

  Future<void> insert(Contact contact) async {
    final db = await _dbService.database;
    await db.insert('contacts', contact.toMap());
  }

  Future<void> update(Contact contact) async {
    final db = await _dbService.database;
    await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _dbService.database;
    await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
```

### Step 4: Service层开发

创建 `lib/services/contact_service.dart`:
```dart
class ContactService {
  final ContactRepository _repository;
  final TagRepository _tagRepository;
  final EventRepository _eventRepository;

  ContactService(
    this._repository,
    this._tagRepository,
    this._eventRepository,
  );

  Future<List<Contact>> getAll() => _repository.getAll();

  Future<Contact> create(Contact contact) async {
    final newContact = contact.copyWith(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repository.insert(newContact);
    return newContact;
  }

  Future<Contact> update(Contact contact) async {
    final updated = contact.copyWith(updatedAt: DateTime.now());
    await _repository.update(updated);
    return updated;
  }

  Future<void> delete(String id) => _repository.delete(id);

  // 按标签搜索
  Future<List<Contact>> searchByTags(
    List<String> tagIds, {
    SearchMode mode = SearchMode.or,
  }) async {
    // 实现搜索逻辑
  }

  // 全文搜索
  Future<List<Contact>> search(String keyword) async {
    // 实现搜索逻辑
  }
}

enum SearchMode { or, and }
```

### Step 5: Provider状态管理

创建 `lib/providers/contact_provider.dart`:
```dart
class ContactProvider extends ChangeNotifier {
  final ContactService _service;
  List<Contact> _contacts = [];
  bool _loading = false;
  String? _error;

  List<Contact> get contacts => _contacts;
  bool get loading => _loading;
  String? get error => _error;

  ContactProvider(this._service);

  Future<void> loadContacts() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _contacts = await _service.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createContact(Contact contact) async {
    try {
      final newContact = await _service.create(contact);
      _contacts.add(newContact);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // 其他操作方法
}
```

### Step 6: UI开发

创建 `lib/screens/contacts/contacts_list_screen.dart`:
```dart
class ContactsListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通讯录')),
      body: Consumer<ContactProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.contacts.isEmpty) {
            return const Center(
              child: Text('暂无通讯人'),
            );
          }

          return ListView.builder(
            itemCount: provider.contacts.length,
            itemBuilder: (context, index) {
              final contact = provider.contacts[index];
              return ContactListItem(contact: contact);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 导航到创建页面
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

---

## 调试与测试

### 运行应用

```bash
# 运行到macOS
flutter run -d macos

# 运行到iPhone模拟器
flutter run -d "iPhone 14"

# Release模式运行
flutter run --release
```

### 调试

```bash
# 启用调试信息
flutter run --verbose

# 附加调试器
flutter attach
```

### 测试

```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/services/contact_service_test.dart

# 生成覆盖率报告
flutter test --coverage
lcov --remove coverage/lcov.info 'lib/generated/*' -o coverage/lcov.info
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 常见问题与解决方案

### Q1: 数据库文件位置在哪里？
**A**: 使用`getDatabasesPath()`获取数据库目录路径，在macOS上通常是`~/Library/Application Support/com.kongo/`

### Q2: 如何处理日期时间？
**A**: 使用`intl`包进行国际化格式化，存储时使用`millisecondsSinceEpoch`

### Q3: 如何处理图片缓存？
**A**: 使用`image_cache_manager`或`cached_network_image`包

### Q4: 性能瓶颈在哪里？
**A**: 使用DevTools进行性能分析，关注数据库查询和UI渲染

---

## 打包与发布

### macOS打包

```bash
# 构建macOS应用
flutter build macos --release

# 应用位置
build/macos/Build/Products/Release/kongo.app

# 创建dmg文件（可选）
# 使用第三方工具如create-dmg
```

### 代码签名（开发者账户）

```bash
# 使用Xcode进行代码签名配置
open macos/Runner.xcworkspace

# 在Xcode中配置Team ID和Bundle ID
```

---

## 版本管理

### Semantic Versioning (语义化版本)
- MAJOR: 主版本 (不兼容的API变更)
- MINOR: 次版本 (向后兼容的新功能)
- PATCH: 修订版本 (向后兼容的bug修复)

格式: `MAJOR.MINOR.PATCH` 如 `1.0.0`

### Commit消息规范

```
<type>(<scope>): <subject>

<body>

<footer>
```

类型:
- `feat`: 新功能
- `fix`: 修复bug
- `docs`: 文档更新
- `style`: 代码风格调整
- `refactor`: 代码重构
- `perf`: 性能优化
- `test`: 添加测试

例如:
```
feat(contact): add search by tags functionality

Implement OR and AND search modes for multiple tags.
Add filter algorithm and unit tests.

Closes #123
```

---

## 资源链接

- [Flutter官方文档](https://flutter.dev/docs)
- [Dart编程指南](https://dart.dev/guides)
- [Provider状态管理](https://pub.dev/packages/provider)
- [SQLite教程](https://www.sqlite.org/docs.html)
- [Flutter性能优化](https://flutter.dev/docs/testing/best-practices)

---

**最后更新**: 2026年3月6日
