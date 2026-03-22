# Kongo 开发指南

## 文档定位

本文档回答四类问题：

1. 如何把环境拉起来
2. 当前代码结构是什么
3. 改代码时要遵守什么边界
4. 怎样验证改动没有破坏现有行为

## 当前环境

### 已验证基线
- macOS Ventura 13.7.8 Intel
- Flutter 3.35.7
- Dart 3.9.2
- Xcode 15.2
- Flutter SDK 路径：`~/development/flutter`

### 平台状态
- macOS：已验证
- iOS：已生成工程，未完整验证
- Windows：已生成工程，未完整验证

### 网络规则
- 可能访问 Google / pub / Flutter 远端资源的命令，先执行 `source ~/.zshrc && proxyon`
- 本地 `localhost` 或本机文件访问不应走代理

### 包管理与原生集成约束
- 当前机器优先走 Swift Package Manager 路径
- 不要默认假设 CocoaPods 可用且稳定
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
├── main.dart
├── config/
├── dev/
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
├── models/
├── providers/
├── repositories/
├── services/
├── test_helpers/
└── widgets/
```

## 分层约束

### 基本链路

```text
Screen -> Widget / Action -> Provider -> Read Service / Service -> Repository -> Database
```

### Screen
- 只做页面编排、导航与状态切换
- 不直接承担跨 repository 聚合逻辑
- 如果 screen 开始长出太多动作方法或 section builder，应及时下沉

### Widget
- 负责复用 UI
- 不承载持久化逻辑

### Provider
- 管理页面状态、错误、初始化标记、异步刷新
- 复杂写流程依赖 `Service`
- 复杂读流程优先依赖 `services/read/`

### Service
- 管理业务规则、校验与写侧编排

### Read Service
- 管理只读聚合
- 不写入数据库

### Repository
- 只负责数据访问与批量查询

## 当前架构事实

### 已落地的 read-side 模式
- `ContactReadService`：联系人详情聚合
- `EventReadService`：事件列表与事件详情聚合

### 已落地的页面级 Provider
- `ContactDetailProvider`
- `EventsListProvider`
- `EventDetailProvider`
- 以及标签、总结、附件、文件库、全局检索相关 provider

### 当前已淘汰或需要避免的模式
- screen 直接拿 service locator 编排复杂查询
- 把读模型聚合散落在 screen 的 `FutureBuilder` 中
- 继续把“事件状态”当成当前产品主语义

## 命名与编码规范

### 命名
- 文件名：snake_case
- 类型名：PascalCase
- 成员名：camelCase

### import 顺序
1. Dart 标准库
2. Flutter SDK
3. 第三方包
4. 项目内代码

### 代码风格
- 优先小步修改，不重写无关模块
- 沿用现有中文文案风格
- 优先复用现有 token、共享 widget 与 helper
- 不把业务逻辑塞回 screen

## 页面开发约束

### Screen 保持薄层
当页面开始出现以下迹象时，应在同次任务中拆分：

1. 多个 section builder
2. 多个确认 / 跳转 / 删除动作
3. 多段格式化辅助逻辑

优先拆分到：
- 同目录 `*_actions.dart`
- 页面专属 section widget
- 通用 widget / utils

## 数据模型校准

### 事件
- 当前 `Event` 模型不含 `status`
- 数据库仍保留 `events.status` 兼容列

### 总结
- 当前主模型是 `DailySummary`
- 表为 `daily_summaries`
- 历史 `event_summaries` 仅用于旧版本迁移

## 测试与验证

### 建议最小验证集

```bash
source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze
source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter test
```

### 测试基线现状
- provider tests
- repository tests
- service tests
- read service tests
- widget tests
- SQLite FFI harness

### 测试实现注意点
- 使用 `sqflite_common_ffi` 跑本地测试
- 对同一数据库连接上的聚合读取，测试里优先保持顺序执行，避免并行锁竞争

## 功能开发建议

### 改读模型页面时
优先检查：
- 是否已有对应 provider
- 是否应该扩展 `services/read/`
- 是否可以补批量查询，而不是在 UI 层做 N+1

### 改写流程时
优先检查：
- 规则是否放在 service
- repository 是否只保留数据访问职责
- provider 是否只做状态编排

### 改 UI 时
优先检查：
- 是否已有共享空态 / 错误态 / skeleton
- 是否已存在同类型 section widget
- 是否能复用 `AppColors`、`AppSpacing`、`AppDimensions`

## 文档维护规则

发生以下变化时，应同步更新文档：

1. 导航结构变化
2. 数据模型主语义变化
3. 数据库 schema / 迁移变化
4. 新 provider / read service / service 成为主路径
5. 平台验证状态变化

更新顺序建议：

1. `README.md`
2. `doc/INDEX.md`
3. 受影响的专题文档