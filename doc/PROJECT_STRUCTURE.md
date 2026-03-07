# Kongo 项目结构说明

**创建日期**: 2026年3月6日  
**状态**: Phase 1 - 基础目录结构已创建

---

## 项目目录树

```
kongo/
├── doc/                              # 📚 项目文档目录
│   ├── README.md                     # 项目总览
│   ├── PROJECT_PLAN.md               # 项目规划
│   ├── DATABASE_DESIGN.md            # 数据库设计
│   ├── API_SPECIFICATION.md          # API规范
│   ├── UI_DESIGN_GUIDE.md            # UI设计规范
│   ├── DEVELOPMENT_GUIDE.md          # 开发指南
│   ├── QUICKSTART.md                 # 快速开始
│   ├── PLANNING_SUMMARY.md           # 规划总结
│   ├── DECISION_LOG.md               # 决策记录
│   ├── PLANNING_COMPLETION_REPORT.md # 完成报告
│   ├── INDEX.md                      # 文档导航
│   └── FINAL_SUMMARY.md              # 最终总结
│
├── lib/                              # 🔨 Dart/Flutter源代码
│   ├── main.dart                     # (待创建) 应用入口
│   │
│   ├── config/                       # ⚙️ 应用配置
│   │   ├── app_config.dart           # (待创建) 应用配置常量
│   │   ├── app_theme.dart            # (待创建) 主题配置
│   │   └── constants.dart            # (待创建) 全局常量
│   │
│   ├── models/                       # 📦 数据模型
│   │   ├── contact.dart              # (待创建) 通讯人模型
│   │   ├── tag.dart                  # (待创建) 标签模型
│   │   ├── event_type.dart           # (待创建) 事件类型模型
│   │   ├── contact_event.dart        # (待创建) 事件模型
│   │   └── database.dart             # (待创建) 数据库模型
│   │
│   ├── services/                     # 🛠️ 业务逻辑服务
│   │   ├── database_service.dart     # (待创建) 数据库初始化服务
│   │   ├── contact_service.dart      # (待创建) 通讯人服务
│   │   ├── tag_service.dart          # (待创建) 标签服务
│   │   └── event_service.dart        # (待创建) 事件服务
│   │
│   ├── repositories/                 # 💾 数据访问层
│   │   ├── contact_repository.dart   # (待创建) 通讯人仓储
│   │   ├── tag_repository.dart       # (待创建) 标签仓储
│   │   └── event_repository.dart     # (待创建) 事件仓储
│   │
│   ├── providers/                    # 📊 状态管理
│   │   ├── contact_provider.dart     # (待创建) 通讯人状态
│   │   ├── tag_provider.dart         # (待创建) 标签状态
│   │   └── event_provider.dart       # (待创建) 事件状态
│   │
│   ├── screens/                      # 📱 页面
│   │   ├── home/
│   │   │   └── home_screen.dart      # (待创建) 首页
│   │   ├── contacts/
│   │   │   ├── contacts_list_screen.dart        # (待创建) 通讯录列表
│   │   │   ├── contact_detail_screen.dart       # (待创建) 通讯人详情
│   │   │   ├── contact_form_screen.dart         # (待创建) 通讯人编辑
│   │   │   └── contact_search_screen.dart       # (待创建) 通讯人搜索
│   │   ├── tags/
│   │   │   ├── tags_screen.dart                 # (待创建) 标签管理
│   │   │   └── tag_form_screen.dart             # (待创建) 标签编辑
│   │   ├── events/
│   │   │   ├── events_screen.dart               # (待创建) 事件列表
│   │   │   └── event_form_screen.dart           # (待创建) 事件编辑
│   │   └── settings/
│   │       └── settings_screen.dart             # (待创建) 设置页面
│   │
│   ├── widgets/                      # 🧩 可复用组件
│   │   ├── common/
│   │   │   ├── custom_app_bar.dart              # (待创建) 自定义应用栏
│   │   │   ├── custom_button.dart               # (待创建) 自定义按钮
│   │   │   └── empty_state.dart                 # (待创建) 空状态提示
│   │   ├── contact/
│   │   │   ├── contact_card.dart                # (待创建) 通讯人卡片
│   │   │   ├── contact_item.dart                # (待创建) 通讯人列表项
│   │   │   └── tag_chip.dart                    # (待创建) 标签chip
│   │   └── event/
│   │       ├── event_item.dart                  # (待创建) 事件列表项
│   │       └── event_timeline.dart              # (待创建) 事件时间线
│   │
│   ├── utils/                        # 🛠️ 工具函数
│   │   ├── date_utils.dart           # (待创建) 日期处理工具
│   │   ├── string_utils.dart         # (待创建) 字符串处理工具
│   │   ├── uuid_utils.dart           # (待创建) UUID生成工具
│   │   └── logger.dart               # (待创建) 日志工具
│   │
│   └── exceptions/                   # ⚠️ 异常定义
│       ├── app_exception.dart        # (待创建) 应用异常基类
│       ├── database_exception.dart   # (待创建) 数据库异常
│       └── validation_exception.dart # (待创建) 验证异常
│
├── test/                             # 🧪 测试目录
│   ├── models/
│   │   └── .gitkeep
│   ├── services/
│   │   └── .gitkeep
│   ├── repositories/
│   │   └── .gitkeep
│   └── widgets/
│       └── .gitkeep
│
├── pubspec.yaml                      # (待创建) 项目配置文件
├── analysis_options.yaml             # (待创建) Dart分析选项
├── .gitignore                        # (已存在) Git忽略文件
├── LICENSE                           # (已存在) 开源协议
└── PROJECT_STRUCTURE.md              # (本文件) 项目结构说明
```

---

## 目录说明

### `/doc` - 文档目录 📚

存放所有项目文档和规划文件。包括：
- 项目规划和需求文档
- 数据库设计文档
- API规范文档
- UI/UX设计规范
- 开发指南
- 决策日志

**文件数**: 12个  
**用途**: 项目规划和参考  
**维护**: 定期更新

### `/lib` - 源代码目录 🔨

所有Dart/Flutter源代码都在这个目录下，按功能分层组织。

#### `/lib/config` - 配置层 ⚙️
存放应用级别的配置、主题、常量等。
- `app_config.dart` - 应用配置（名称、版本等）
- `app_theme.dart` - Material主题配置
- `constants.dart` - 全局常量（间距、颜色等）

#### `/lib/models` - 数据模型层 📦
定义应用中使用的数据结构。
- `contact.dart` - 通讯人模型
- `tag.dart` - 标签模型
- `event_type.dart` - 事件类型模型
- `contact_event.dart` - 事件模型
- `database.dart` - 数据库相关模型

#### `/lib/services` - 业务逻辑层 🛠️
实现应用的业务逻辑。
- `database_service.dart` - 数据库初始化和管理
- `contact_service.dart` - 通讯人相关业务逻辑
- `tag_service.dart` - 标签相关业务逻辑
- `event_service.dart` - 事件相关业务逻辑

#### `/lib/repositories` - 数据访问层 💾
封装数据库操作，提供CRUD接口。
- `contact_repository.dart` - 通讯人数据访问
- `tag_repository.dart` - 标签数据访问
- `event_repository.dart` - 事件数据访问

#### `/lib/providers` - 状态管理层 📊
使用Provider管理应用状态。
- `contact_provider.dart` - 通讯人状态管理
- `tag_provider.dart` - 标签状态管理
- `event_provider.dart` - 事件状态管理

#### `/lib/screens` - 页面层 📱
应用的所有页面/屏幕。
- `home/` - 首页相关页面
- `contacts/` - 通讯人相关页面
- `tags/` - 标签管理页面
- `events/` - 事件管理页面
- `settings/` - 设置页面

#### `/lib/widgets` - UI组件库 🧩
可复用的UI组件。
- `common/` - 通用组件（AppBar、按钮等）
- `contact/` - 通讯人相关组件
- `event/` - 事件相关组件

#### `/lib/utils` - 工具函数 🛠️
应用级别的工具函数。
- `date_utils.dart` - 日期处理
- `string_utils.dart` - 字符串处理
- `uuid_utils.dart` - UUID生成
- `logger.dart` - 日志记录

#### `/lib/exceptions` - 异常定义 ⚠️
应用中使用的自定义异常。
- `app_exception.dart` - 基础异常类
- `database_exception.dart` - 数据库异常
- `validation_exception.dart` - 验证异常

### `/test` - 测试目录 🧪

单元测试和Widget测试的代码。
- `models/` - 数据模型测试
- `services/` - Service层测试
- `repositories/` - Repository层测试
- `widgets/` - Widget测试

---

## 架构概览

```
┌─────────────────────────────────────┐
│      screens/ (页面)                 │
│    (用户交互界面)                    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│    widgets/ (UI组件)                │
│      (可复用的UI组件库)             │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   providers/ (状态管理)              │
│   (使用Provider管理应用状态)         │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│    services/ (业务逻辑)              │
│  (业务规则、算法实现、复杂逻辑)     │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│  repositories/ (数据访问)            │
│   (CRUD操作、数据库查询)            │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      models/ (数据模型)              │
│     (Entity定义、toMap/fromMap)     │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│    SQLite数据库 (持久化层)          │
└─────────────────────────────────────┘
```

---

## 下一步任务 (Phase 1)

### ✅ 已完成
- [x] 项目规划文档创建 (12份)
- [x] 基础目录结构创建

### 📋 待做事项

#### 第1周 - 项目初始化
- [ ] 创建Flutter项目或初始化现有项目
- [ ] 配置 `pubspec.yaml` (添加依赖包)
- [ ] 创建 `analysis_options.yaml` (Lint规则)
- [ ] 创建基础配置文件
  - [ ] `lib/config/app_config.dart`
  - [ ] `lib/config/app_theme.dart`
  - [ ] `lib/config/constants.dart`

#### 第2周 - 数据模型和异常
- [ ] 创建异常类
  - [ ] `lib/exceptions/app_exception.dart`
  - [ ] `lib/exceptions/database_exception.dart`
  - [ ] `lib/exceptions/validation_exception.dart`
- [ ] 创建数据模型
  - [ ] `lib/models/contact.dart`
  - [ ] `lib/models/tag.dart`
  - [ ] `lib/models/event_type.dart`
  - [ ] `lib/models/contact_event.dart`

#### 第3周 - 数据库和Repository
- [ ] 创建数据库服务 `lib/services/database_service.dart`
- [ ] 创建Repository层
  - [ ] `lib/repositories/contact_repository.dart`
  - [ ] `lib/repositories/tag_repository.dart`
  - [ ] `lib/repositories/event_repository.dart`
- [ ] 编写单元测试

#### 第4周 - Service层和Provider
- [ ] 创建Service层
  - [ ] `lib/services/contact_service.dart`
  - [ ] `lib/services/tag_service.dart`
  - [ ] `lib/services/event_service.dart`
- [ ] 创建Provider
  - [ ] `lib/providers/contact_provider.dart`
  - [ ] `lib/providers/tag_provider.dart`
  - [ ] `lib/providers/event_provider.dart`
- [ ] 编写单元测试

---

## 文件命名规范

### Dart文件
- 文件名使用 snake_case: `contact_service.dart`
- 一个文件只定义一个主要类
- 导入按顺序排列：Dart标准库 → Flutter SDK → 第三方包 → 项目文件

### 类名
- 使用 PascalCase: `class ContactService`
- 枚举使用 PascalCase: `enum SearchMode`
- 常量类使用 PascalCase: `class Constants`

### 方法和变量
- 使用 camelCase: `void getContacts()`, `var userName`
- 私有成员前缀 `_`: `var _privateVar`, `void _privateMethod()`

### 常量
- 大写带下划线: `const String APP_NAME`

更多规范详见: `/doc/DEVELOPMENT_GUIDE.md`

---

## 快速查找指南

### 我想查找...

| 需求 | 查看文档/位置 |
|------|-------------|
| 项目总体规划 | `/doc/PROJECT_PLAN.md` |
| 数据库设计 | `/doc/DATABASE_DESIGN.md` |
| API接口规范 | `/doc/API_SPECIFICATION.md` |
| UI设计规范 | `/doc/UI_DESIGN_GUIDE.md` |
| 开发指南 | `/doc/DEVELOPMENT_GUIDE.md` |
| 快速开始 | `/doc/QUICKSTART.md` |
| 代码示例 | `/doc/DEVELOPMENT_GUIDE.md` 的开发步骤 |
| 项目结构 | 本文件 `PROJECT_STRUCTURE.md` |

---

## 相关文档链接

- 📖 项目总览: [`doc/README.md`](doc/README.md)
- 📋 项目规划: [`doc/PROJECT_PLAN.md`](doc/PROJECT_PLAN.md)
- 🗄️ 数据库设计: [`doc/DATABASE_DESIGN.md`](doc/DATABASE_DESIGN.md)
- 📡 API规范: [`doc/API_SPECIFICATION.md`](doc/API_SPECIFICATION.md)
- 🎨 UI设计: [`doc/UI_DESIGN_GUIDE.md`](doc/UI_DESIGN_GUIDE.md)
- 🛠️ 开发指南: [`doc/DEVELOPMENT_GUIDE.md`](doc/DEVELOPMENT_GUIDE.md)
- 🚀 快速开始: [`doc/QUICKSTART.md`](doc/QUICKSTART.md)
- 📍 文档导航: [`doc/INDEX.md`](doc/INDEX.md)

---

## 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0 | 2026-03-06 | 初始项目结构 |

---

**创建日期**: 2026年3月6日  
**状态**: ✅ Phase 1 完成  
**下一步**: 创建基础配置文件 (Phase 2)  

