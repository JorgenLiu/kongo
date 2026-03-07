# Kongo 快速开始指南

## 概述

本指南将帮助你快速设置和启动Kongo项目开发。

---

## 前置条件

- macOS 11.0+
- Xcode 13.0+
- Flutter 3.0+
- Dart 2.18+
- Git

---

## 第1步: 环境检查

```bash
# 检查Flutter安装
flutter --version

# 检查Dart安装
dart --version

# 检查开发环境
flutter doctor
```

---

## 第2步: 创建Flutter项目

如果还未创建Flutter项目，执行以下命令：

```bash
cd /Users/geliu/dev/kongo
flutter create --org com.kongo --platforms macos,ios,windows kongo
cd kongo
```

---

## 第3步: 添加项目依赖

编辑 `pubspec.yaml`，添加以下依赖：

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 状态管理
  provider: ^6.0.0
  
  # 数据库
  sqflite: ^2.3.0
  path_provider: ^2.0.0
  
  # 工具库
  uuid: ^4.0.0
  intl: ^0.19.0
  
  # UI组件
  flutter_colorpicker: ^1.0.0
  
  # 图片处理
  image_picker: ^1.0.0
  image: ^4.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  mockito: ^5.4.0
```

然后执行：

```bash
flutter pub get
```

---

## 第4步: 创建项目结构

执行以下命令创建项目的目录结构：

```bash
cd lib

# 创建主要目录
mkdir -p {config,models,services,repositories,providers,screens,widgets,utils,exceptions}

# 创建子目录
mkdir -p screens/{home,contacts,tags,events,settings}
mkdir -p screens/contacts/{widgets}
mkdir -p widgets/{common,contact,event}
```

---

## 第5步: 初始化主应用文件

创建 `lib/main.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'config/app_config.dart';
import 'services/database_service.dart';
import 'providers/contact_provider.dart';
import 'providers/tag_provider.dart';
import 'providers/event_provider.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化数据库
  final databaseService = DatabaseService();
  await databaseService.database;
  
  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>(create: (_) => databaseService),
        // 添加其他providers
        ChangeNotifierProvider<ContactProvider>(
          create: (context) => ContactProvider(
            // 初始化逻辑
          ),
        ),
        // 其他providers...
      ],
      child: const KongoApp(),
    ),
  );
}

class KongoApp extends StatelessWidget {
  const KongoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kongo',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

---

## 第6步: 创建基础配置文件

### lib/config/app_config.dart

```dart
class AppConfig {
  static const String appName = 'Kongo';
  static const String appVersion = '1.0.0';
  static const String databaseName = 'kongo.db';
  static const int databaseVersion = 1;
}
```

### lib/config/app_theme.dart

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF2196F3),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF2196F3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF2196F3),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
```

### lib/config/constants.dart

```dart
class AppConstants {
  // 间距
  static const double spacingXS = 4;
  static const double spacingSM = 8;
  static const double spacingMD = 16;
  static const double spacingLG = 24;
  static const double spacingXL = 32;

  // 圆角
  static const double radiusXS = 4;
  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 16;
  static const double radiusXL = 28;

  // 其他
  static const int itemsPerPage = 20;
  static const Duration animationDuration = Duration(milliseconds: 300);
}
```

---

## 第7步: 创建数据模型

### lib/models/contact.dart

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

  @override
  String toString() => 'Contact(id: $id, name: $name)';
}
```

### lib/models/tag.dart

```dart
class Tag {
  final String id;
  final String name;
  final String? color;
  final DateTime createdAt;

  Tag({
    required this.id,
    required this.name,
    this.color,
    required this.createdAt,
  });

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  Tag copyWith({
    String? id,
    String? name,
    String? color,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

---

## 第8步: 创建数据库服务

### lib/services/database_service.dart

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';

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
    final dbDir = await getApplicationDocumentsDirectory();
    final dbPath = join(dbDir.path, AppConfig.databaseName);

    return openDatabase(
      dbPath,
      version: AppConfig.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 创建contacts表
    await db.execute('''
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
    ''');

    // 创建其他表的SQL语句...
    // 详见DATABASE_DESIGN.md
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // 数据库升级逻辑
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
```

---

## 第9步: 运行项目

```bash
# 运行到macOS
flutter run -d macos

# 或在VS Code中按F5

# Release模式运行
flutter run -d macos --release
```

---

## 第10步: 验证项目

运行以下命令验证项目配置：

```bash
# 检查代码风格
dart analyze

# 格式化代码
dart format lib/

# 运行测试
flutter test
```

---

## 下一步

1. 阅读 `PROJECT_PLAN.md` 了解完整的项目规划
2. 参考 `DATABASE_DESIGN.md` 完成数据库设计
3. 查看 `API_SPECIFICATION.md` 实现业务逻辑
4. 遵循 `UI_DESIGN_GUIDE.md` 进行UI开发
5. 按 `DEVELOPMENT_GUIDE.md` 中的步骤进行开发

---

## 常见问题

### Q: 如何在模拟器上运行？
```bash
flutter emulators
flutter run -d <emulator_name>
```

### Q: 如何调试应用？
```bash
# 启用调试日志
flutter run --verbose

# 在DevTools中调试
flutter pub global activate devtools
devtools
```

### Q: 如何安装新的package？
```bash
flutter pub add <package_name>
flutter pub get
```

---

**最后更新**: 2026年3月6日

