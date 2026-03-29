# Kongo 文档入口

本文档用于回答两个问题：

1. 当前项目真实状态是什么
2. 哪些文档是事实源，哪些只是历史记录

## 当前项目事实

- 当前主平台是 macOS，iOS / Windows 仅保留平台工程，未完成同等强度验证
- 当前数据库 schema 版本是 9（v10 将随 Quick Capture `quick_notes` 表新增）
- 当前核心主线是：联系人 → 事件 → 每日总结 → 附件沉淀
- 当前总结主模型是 `DailySummary`，不是旧版事件级总结流
- 当前事件运行时模型不再暴露 `status`，数据库仅保留兼容列
- 当前日历已经支持展示联系人重要日期、公共纪念日、营销节点，并提供类别开关
- 当前已经引入独立待办表，支持待办组、子项以及多联系人/多事件关联
- 当前 AI 基础设施底座已落地：Provider 抽象、OpenAI 兼容接入、配置持久化、设置页测试连接与应用启动注入均已完成
- 首页 AI 日报 V1 技术上可用，但**经 2026-03-28 评估后已不再作为首页主路径**；AI 将用于数据成熟后的用户主动触发场景
- **当前下一步核心优先级**：P0a 首页复原（移除 AI 日报卡）→ P0b macOS 菜单栏 Quick Capture → P1 输入解析 → P2 规则驱动提醒卡

## 文档分层

### 核心事实源

以下文档应优先维护，并在代码变化后及时同步：

| 文档 | 用途 |
| ---- | ---- |
| `PROJECT_PLAN.md` | 产品定位、当前边界、近期路线图 |
| `PROJECT_STATUS.md` | 已完成 / 部分完成 / 未开始能力盘点 |
| `DEVELOPMENT_GUIDE.md` | 环境、架构边界、开发与验证方式 |
| `DATABASE_DESIGN.md` | 当前 schema、迁移、兼容字段与缺失结构 |
| `API_SPECIFICATION.md` | Repository / Service / Read Service / Provider 契约 |
| `UI_DESIGN_GUIDE.md` | 当前已生效的视觉、布局、交互与 UI 缺口 |

### 参考文档

以下文档仍有参考价值，但不应作为当前产品事实源：（当前无需专门保留的参考文档）

### 当前战略文档

| 文档 | 用途 |
| ---- | ---- |
| `PRODUCT_STRATEGY_2026.md` | 产品定位、AI 接入路线、数据入口策略、云同步决策（2026-03，已随 2026-03-28 更新）|
| `PRODUCT_DIRECTION_2026_03_28.md` | **2026-03-28 方向确认记录**：放弃 AI 首页主角、确立“记一句话”核心交互简语、菜单栏为主入口、首页工作台重构、AI 重新定位 |
| `TECH_STACK_DECISIONS_2026_03_28.md` | **2026-03-28 技术选型决策**：Flutter 确认、Tauri 否决原因、Swift 桥接方案、CloudKit 同步策略、输入解析路线 |
| `CODE_REVIEW.md` | 代码审查记录 |

### 待执行实施计划

| 文档 | 内容 |
| ---- | ---- |
| `PLAN_QUICK_CAPTURE_IMPL.md` | **当前主线实施计划**：P0a 首页复原 → P0b macOS 菜单栏 Quick Capture → P1 输入解析 → P2 规则驱动提醒卡 |
| `PLAN_OUTLOOK_CALENDAR_SYNC_V1.md` | Outlook 日历接入 v1：Microsoft Graph OAuth、本地 token 存储、会议单向同步、设置页连接与立即同步入口 |
| `PLAN_AI_API_KEY_SECURE_STORAGE_2026_03_27.md` | AI API key 安全存储正式设计稿，包含 macOS/iOS/Windows 方案、迁移策略与详细任务拆分 |
### 已落地实施记录

| 文档 | 性质 |
| ---- | ---- |
| ~~`PLAN_SCHEMA_MIGRATION_V9.md`~~ | 已删除；Schema v9 迁移完整落地，代码即记录 |
| ~~`PLAN_AI_INFRASTRUCTURE.md`~~ | 已删除；AI 基础设施全部落地，见 `PROJECT_STATUS.md` |
| ~~`PLAN_AI_TESTING.md`~~ | 已删除；测试已全部补齐，见代码库 `test/` |
| ~~`PLAN_HOME_AI_DAILY_BRIEF_V1.md`~~ | 已删除；首页 AI 日报从主路径上撤，见 `PRODUCT_DIRECTION_2026_03_28.md` |

### 当前评审

当前无活跃评审文档。过往评审（UI_SCREENSHOT_REVIEW、HOME_WEEKLY_PLAN 等）已完成并融入代码，不再单独维护。

### 历史记录

以下文档用于回看过程，不应用来判断"现在项目是什么样"（这些文件已不存在于 doc/）：

| 文档 | 性质 |
| ---- | ---- |
| `HOME_UI_UX_DETAIL_PLAN_2026_03_26.md` | 已删除；规划了旧版 AI 日报中心首页布局，已被新方向取代 |
| `UI_REVIEW_2026_03_22.md` | 某一时点的 UI/UX 评审（已删除）|
| `UI_BEAUTIFICATION_PLAN.md` | 已完成 UI 美化工作的归档说明（已删除）|

## 建议阅读顺序

### 第一次了解项目

1. `PROJECT_PLAN.md`
2. `PROJECT_STATUS.md`
3. `DEVELOPMENT_GUIDE.md`
4. `UI_DESIGN_GUIDE.md`

### 改业务与数据

1. `PROJECT_PLAN.md`
2. `DATABASE_DESIGN.md`
3. `API_SPECIFICATION.md`
4. `DEVELOPMENT_GUIDE.md`

### 改页面与交互

1. `UI_DESIGN_GUIDE.md`
2. `PROJECT_STATUS.md`
3. `DEVELOPMENT_GUIDE.md`

## 当前建议关注点

1. 首页复原（移除 AI 日报卡）→ macOS 菜单栏 Quick Capture → 输入解析（见 `PLAN_QUICK_CAPTURE_IMPL.md`）
2. 规则驱动单张提醒卡（P2，Quick Capture 稳定后）
3. 系统提醒跨平台通知与策略深化
4. 联系人详情中的附件与里程碑体验深化
5. 待办组与待办来源整合
