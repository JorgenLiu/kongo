# Kongo - 通讯录和日程管理应用

一个跨平台的Flutter应用，用于管理通讯人信息和重要日期事件。

## 📱 应用特性

### 核心功能
- **通讯人管理**: 创建、编辑、删除通讯人信息
- **智能标签**: 为通讯人添加多个标签，支持灵活搜索
- **日程管理**: 管理生日、会面日期、结婚纪念日等重要时间节点
- **智能搜索**: 支持全文搜索和多标签组合搜索
- **提醒功能**: 设置重要日期的提前提醒

### 支持平台
- ✅ macOS (优先实现)
- 🚧 Windows (计划中)
- 🚧 iOS (计划中)

## 🛠 技术栈

| 技术         | 说明       |
| ------------ | ---------- |
| **Flutter**  | 3.0+       |
| **Dart**     | 2.18+      |
| **SQLite**   | 本地数据库 |
| **Provider** | 状态管理   |
| **sqflite**  | SQLite驱动 |

## 📚 项目文档

本项目包含完整的规划和设计文档：

### 核心文档
- **[PROJECT_PLAN.md](PROJECT_PLAN.md)** - 项目总体规划
  - 功能需求分析
  - 数据库设计
  - 项目结构规划
  - 开发阶段计划

- **[DATABASE_DESIGN.md](DATABASE_DESIGN.md)** - 数据库详细设计
  - 数据表结构
  - ER图和关系
  - SQL查询示例
  - 数据备份与恢复

- **[API_SPECIFICATION.md](API_SPECIFICATION.md)** - API接口规范
  - Service接口设计
  - Repository接口设计
  - Provider状态管理
  - 使用示例

- **[UI_DESIGN_GUIDE.md](UI_DESIGN_GUIDE.md)** - UI/UX设计规范
  - 色彩系统
  - 排版规范
  - 组件设计
  - 页面布局

- **[DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md)** - 开发指南
  - 环境设置
  - 架构设计
  - 编码规范
  - 测试指南

- **[QUICKSTART.md](QUICKSTART.md)** - 快速开始指南
  - 环境检查
  - 项目初始化
  - 依赖安装
  - 运行步骤

## 🚀 快速开始

### 前置条件
```bash
# 检查Flutter安装
flutter --version

# 检查Dart安装
dart --version

# 检查开发环境
flutter doctor
```

### 安装依赖
```bash
cd kongo
flutter pub get
```

### 运行应用
```bash
# macOS
flutter run -d macos

# iOS模拟器
flutter run -d "iPhone 14"

# 指定Release模式
flutter run --release
```

## 📖 项目结构

```
kongo/
├── lib/
│   ├── main.dart                    # 应用入口
│   ├── config/                      # 应用配置
│   ├── models/                      # 数据模型
│   ├── services/                    # 业务逻辑服务
│   ├── repositories/                # 数据访问层
│   ├── providers/                   # 状态管理
│   ├── screens/                     # 页面
│   ├── widgets/                     # 可复用组件
│   ├── utils/                       # 工具函数
│   └── exceptions/                  # 异常定义
├── test/                            # 测试目录
├── PROJECT_PLAN.md                  # 项目规划
├── DATABASE_DESIGN.md               # 数据库设计
├── API_SPECIFICATION.md             # API规范
├── UI_DESIGN_GUIDE.md               # UI设计
├── DEVELOPMENT_GUIDE.md             # 开发指南
├── QUICKSTART.md                    # 快速开始
└── pubspec.yaml                     # 项目配置
```

## 🗄️ 数据模型

### 核心实体

#### Contact (通讯人)
```dart
- id: String (主键)
- name: String (姓名)
- phone: String? (电话)
- email: String? (邮箱)
- address: String? (地址)
- notes: String? (备注)
- avatar: Blob? (头像)
- createdAt: DateTime
- updatedAt: DateTime
- tags: List<Tag> (标签)
- events: List<ContactEvent> (事件)
```

#### Tag (标签)
```dart
- id: String (主键)
- name: String (标签名)
- color: String? (颜色)
- createdAt: DateTime
```

#### ContactEvent (事件)
```dart
- id: String (主键)
- contactId: String (外键)
- eventTypeId: String (外键)
- date: String (YYYY-MM-DD)
- reminderEnabled: bool (是否提醒)
- reminderDays: int (提前天数)
- notes: String? (备注)
- createdAt: DateTime
- updatedAt: DateTime
```

## 🎯 开发阶段

### Phase 1: 项目初始化与基础架构 (第1-2周)
- [ ] 创建Flutter项目
- [ ] 配置项目结构
- [ ] 设置依赖包
- [ ] 实现数据库初始化

### Phase 2: 数据模型与数据库 (第2-3周)
- [ ] 设计和实现数据模型
- [ ] 实现SQLite数据库操作
- [ ] 创建Repository层
- [ ] 编写单元测试

### Phase 3: 核心业务逻辑层 (第3-4周)
- [ ] 实现Service层
- [ ] 实现Provider状态管理
- [ ] 业务逻辑单元测试

### Phase 4: UI开发 (第4-6周)
- [ ] 通讯人列表页面
- [ ] 通讯人详情页面
- [ ] 标签管理页面
- [ ] 事件管理页面
- [ ] 搜索功能页面

### Phase 5: 功能集成与测试 (第6-7周)
- [ ] 端到端测试
- [ ] 性能优化
- [ ] Bug修复

### Phase 6: macOS适配与发布 (第7-8周)
- [ ] macOS平台特性适配
- [ ] 打包与签名
- [ ] 应用分发

## 📋 第一版需求清单

### 通讯人管理
- [x] 创建通讯人
- [x] 编辑通讯人信息
- [x] 删除通讯人
- [x] 查看通讯人列表

### 标签系统
- [x] 为通讯人添加标签
- [x] 管理标签
- [x] 单个标签查找
- [x] 多个标签组合查找（OR/AND）

### 时间节点管理
- [x] 创建时间节点（生日、会面日期等）
- [x] 编辑时间节点
- [x] 查看时间节点
- [x] 删除时间节点

### 数据持久化
- [x] SQLite本地存储
- [x] 数据备份与恢复接口设计

## 🎨 UI/UX设计

### 色彩方案
- **Primary**: #2196F3 (蓝色)
- **Secondary**: #03DAC6 (青色)
- **Error**: #B00020 (红色)
- **Success**: #4CAF50 (绿色)

### 组件
- 响应式设计
- Material 3 设计规范
- 深色模式支持
- 无障碍设计

详见 [UI_DESIGN_GUIDE.md](UI_DESIGN_GUIDE.md)

## 🧪 测试

```bash
# 运行所有测试
flutter test

# 生成覆盖率报告
flutter test --coverage

# 特定测试文件
flutter test test/services/contact_service_test.dart
```

目标覆盖率:
- Service层: ≥90%
- Repository层: ≥85%
- 总体: ≥80%

## 🔧 开发工具

### 代码质量
```bash
# 代码分析
dart analyze

# 代码格式化
dart format lib/

# Flutter Lint
flutter analyze
```

### 调试
```bash
# 启用verbose日志
flutter run --verbose

# 使用DevTools
flutter pub global activate devtools
devtools
```

## 📦 依赖管理

### 核心依赖
- `provider: ^6.0.0` - 状态管理
- `sqflite: ^2.3.0` - SQLite数据库
- `uuid: ^4.0.0` - UUID生成
- `intl: ^0.19.0` - 国际化

### 开发工具
- `flutter_lints: ^3.0.0` - Lint规则
- `mockito: ^5.4.0` - Mock框架

更新依赖:
```bash
flutter pub upgrade
flutter pub outdated
```

## 📝 命名规范

### 文件名
- 使用snake_case: `contact_service.dart`

### 类名
- 使用PascalCase: `class ContactService`

### 变量和方法
- 使用camelCase: `var userName`

### 常量
- 大写带下划线: `const String APP_NAME`

详见 [DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md)

## 🐛 问题报告

发现bug或有功能建议，请提交Issue或Pull Request。

## 📄 许可证

[查看LICENSE文件](LICENSE)
An address list App with agenda management. 
