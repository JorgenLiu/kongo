# Kongo 开发指南

## 文档目的

本文档回答四个问题：

1. 当前环境怎么跑起来
2. 当前代码结构怎么分层
3. 改代码时哪些边界不能破坏
4. 改完之后怎样验证

## 当前环境

### 已验证基线

- macOS Ventura 13.7.8 Intel
- Flutter 3.35.7
- Dart 3.9.2
- Xcode 15.2
- Flutter SDK 路径：`~/development/flutter`

### 平台状态

- macOS：已验证
- iOS：工程存在，未完整验证
- Windows：工程存在，未完整验证

### 网络规则

- 可能访问 Google / pub / Flutter 远端资源时，先执行 `source ~/.zshrc && proxyon`
- 本地文件和 `localhost` 不应走代理

### 原生依赖约束

- 当前环境优先走 Swift Package Manager 路径
- 不要默认假设 CocoaPods 稳定可用
- 不要默认依赖 Homebrew 管理 Flutter

## 常用命令

```bash
source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter pub get
source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze
source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter test
source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter run -d macos
source ~/.zshrc && proxyon && cd /Users/jordan.liu/dev/kongo && flutter doctor -v
```

## 项目结构

```text
lib/
├── config/
├── exceptions/
├── models/
├── providers/
├── repositories/
├── screens/
├── services/
│   └── read/
├── utils/
└── widgets/

test/
├── providers/
├── services/
├── test_helpers/
└── widgets/
```

## 分层约束

### 基本链路

```text
Screen -> Widget / Action -> Provider -> Read Service / Service -> Repository -> Database / File System
```

### Screen

- 只负责页面编排、导航与状态切换
- 不直接承担复杂聚合、数据库访问或大段业务逻辑
- 如果 screen 开始长出太多动作方法或 section builder，应及时下沉

### Widget

- 负责展示与局部交互
- 不承担持久化与跨仓储编排

### Provider

- 管理页面状态、初始化标记、错误与刷新行为
- 写流程依赖 `Service`
- 读聚合优先依赖 `services/read/`

### Service

- 负责业务规则、校验、写侧编排

### Read Service

- 只做只读聚合
- 不承担 create / update / delete 规则

### Repository

- 只负责 SQLite CRUD 与批量查询

## 当前主路径

### 已稳定的读侧服务

- `ContactReadService`
- `EventReadService`
- `SummaryReadService`
- `HomeReadService`

### 已稳定的页面级 Provider

- `ContactProvider`
- `ContactDetailProvider`
- `EventsListProvider`
- `EventDetailProvider`
- `TagProvider`
- `SummaryProvider`
- `FilesProvider`
- `GlobalSearchProvider`

### 当前要避免的模式

1. screen 直接拼多段查询
2. 在 widget 内做读侧聚合
3. 把业务规则塞进 repository
4. 继续把事件状态当成当前产品主语义

## 代码约束

### 命名

- 文件：snake_case
- 类型：PascalCase
- 成员：camelCase

### 代码风格

- 优先小步修改，不重写无关模块
- 复用已有 token、共享 widget 与工具函数
- 中文文案优先沿用现有风格
- 生产逻辑不要回流到 screen

### 页面开发

当页面开始出现以下迹象时，应在同次任务中拆分：

1. 多个 section builder
2. 多个确认 / 跳转 / 删除动作
3. 多段格式化或筛选辅助逻辑

优先拆分到：

- 同目录 `*_actions.dart`
- 页面专属 section widget
- 共享 `widgets/` 或 `utils/`

## 数据模型校准

### 事件

- 当前 Dart `Event` 不含 `status`
- 数据库仍保留 `events.status` 兼容列

### 总结

- 当前主模型是 `DailySummary`
- 表为 `daily_summaries`
- 历史 `event_summaries` 仅用于旧版本迁移与兼容

### 日历时间节点

- 当前联系人重要日期、公共纪念日、营销节点已经通过统一读模型进入日历
- 时间节点类别开关已进入设置中心，并持久化到本地数据库
- 当前还没有节气等更多节点源配置

### 待办

- 当前待办已经进入独立表结构与独立页面入口
- 页面主路径应按 `Screen -> Provider -> ReadService/Service -> Repository` 组织
- 总结行动项提取仍可复用，但不要再把待办主状态塞回 `ActionItem` 临时模型

## 测试与验证

### 最小验证集

```bash
source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze
source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter test
```

### 当前测试基线

- provider tests
- service tests
- read service tests
- widget tests
- SQLite FFI harness

### 测试注意点

- 使用 `sqflite_common_ffi` 跑本地测试
- 同一数据库连接上的聚合读取优先顺序执行，避免锁竞争

## 文档维护规则

以下变化发生时，应同步更新文档：

1. 导航结构变化
2. 数据模型主语义变化
3. 数据库 schema / 迁移变化
4. 新的 Service / Read Service / Provider 成为主路径
5. 平台验证状态变化

建议更新顺序：

1. `README.md`
2. `doc/INDEX.md`
3. 受影响的专题文档
