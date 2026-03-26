# Kongo

Kongo 是一个基于 Flutter + Dart + SQLite 的本地优先关系管理应用，围绕联系人、事件、每日总结与附件沉淀组织个人工作信息。当前以 macOS 为主要开发和验证平台，iOS 与 Windows 工程已生成，但尚未完成同等强度的端到端验证。

## 当前产品状态

### 已完成的主能力
- 联系人：列表、关键字搜索、创建、编辑、删除、详情聚合视图
- 标签：创建、编辑、删除、联系人打标、列表检索
- 事件：列表、关键字检索、事件类型过滤、创建、编辑、删除、详情页、参与人角色维护
- 每日总结：列表、按关键字检索、按日期唯一创建、编辑、删除、行动项提取
- 附件：文件复制入库、事件/总结关联、打开、解绑、删除、文件库总览
- 日历：周历 / 月历 / 时间线视图，联系人重要日期节点展示
- 全局检索：跨联系人、事件、每日总结统一搜索，包含命中词高亮与排序
- 读侧聚合：`ContactReadService` 与 `EventReadService`
- 统一 Provider 基础设施：结构化错误、加载态、页面级状态管理
- 测试基线：provider、service、read service、widget、SQLite FFI harness

### 当前壳导航
主导航当前包含 5 个一级页面：

1. 日程
2. 通讯录
3. 检索
4. 总结
5. 设置

标签管理与文件库已实现，但当前通过次级入口进入，而不是一级导航页。

### 当前仍在演进中的部分
- 联系人详情中的“附件模块”仍是轻量入口提示，尚未扩展为独立联系人附件工作台
- 文件库目前以检索和打开为主，尚未补齐排序、筛选、批量操作与预览增强
- 提醒能力已保留事件字段，但尚未打通 macOS / Windows / iOS 的系统提醒闭环
- 时间节点类别开关与更多节点源尚未接入
- 待办中心尚未形成独立模块
- 数据库仍保留 `events.status` 兼容列，但当前运行时事件模型与 UI 已不再使用“事件状态”概念

## 技术栈

### 运行时依赖
- Flutter / Dart
- provider
- sqflite
- path / path_provider
- file_selector
- uuid
- lpinyin

### 测试依赖
- flutter_test
- sqflite_common_ffi

## 快速开始

### 环境约束
- 已验证开发环境：macOS Ventura 13.7.8 Intel
- Flutter SDK 路径：`~/development/flutter`
- 可能访问 Google / Flutter / pub 远端资源的命令，先执行 `source ~/.zshrc && proxyon`
- 当前机器优先使用 Swift Package Manager 路径，不建议依赖 CocoaPods

### 常用命令

```bash
source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter pub get
source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze
source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter test
source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter run -d macos
```

### 构建与打开 macOS 客户端

```bash
source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter build macos
open /Users/jordan.liu/dev/kongo/build/macos/Build/Products/Release/kongo.app
```

## 项目结构

```text
kongo/
├── doc/                      # 项目文档与设计说明
├── lib/
│   ├── config/              # 主题、颜色、尺寸 token
│   ├── exceptions/          # 结构化异常
│   ├── models/              # 领域模型与 draft
│   ├── providers/           # 页面与功能状态管理
│   ├── repositories/        # SQLite 持久化
│   ├── screens/             # 页面编排层
│   ├── services/            # 业务服务与 read-side 服务
│   ├── utils/               # 格式化与辅助函数
│   ├── widgets/             # 复用组件
│   └── main.dart            # 应用入口
├── test/                    # provider / service / widget 测试
├── macos/                   # 当前已验证平台
├── ios/                     # 已生成工程，待完整验证
├── windows/                 # 已生成工程，待完整验证
└── pubspec.yaml
```

## 文档入口

建议按下面顺序阅读：

1. `doc/INDEX.md`：文档导航与当前项目状态
2. `doc/PROJECT_PLAN.md`：产品定位、现状、路线图
3. `doc/DATABASE_DESIGN.md`：数据库结构、迁移与兼容性说明
4. `doc/API_SPECIFICATION.md`：Repository / Service / Read Service / Provider 契约
5. `doc/UI_DESIGN_GUIDE.md`：当前已落地的视觉 token 与交互规范
6. `doc/DEVELOPMENT_GUIDE.md`：环境、架构、约束、测试与开发方式

## 测试

### 建议执行顺序

```bash
source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze
source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter test
```

### 已存在的测试覆盖方向
- Provider 状态流
- Repository / Service 基础 CRUD 与业务规则
- Read Service 聚合
- Shell 导航与关键页面 widget 行为
- SQLite FFI 本地测试基建

## 关键事实

- 当前总结模块的真实模型是“每日总结”`DailySummary`，而不是事件内嵌纪要流
- 当前全局检索覆盖联系人、事件、每日总结，不含附件独立结果卡片
- 当前应用主题已采用暖棕色 Agenda 风格，而非早期蓝青色方案
- 当前事件运行时模型已移除 `status` 字段；数据库保留兼容列，仅用于历史迁移与兼容

## 许可证

详见 `LICENSE`。