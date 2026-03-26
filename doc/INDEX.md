# Kongo 文档入口

本文档用于回答两个问题：

1. 当前项目真实状态是什么
2. 哪些文档是事实源，哪些只是历史记录

## 当前项目事实

- 当前主平台是 macOS，iOS / Windows 仅保留平台工程，未完成同等强度验证
- 当前数据库 schema 版本是 8
- 当前核心主线是：联系人 → 事件 → 每日总结 → 附件沉淀
- 当前总结主模型是 `DailySummary`，不是旧版事件级总结流
- 当前事件运行时模型不再暴露 `status`，数据库仅保留兼容列
- 当前日历已经支持展示联系人重要日期、公共纪念日、营销节点，并提供类别开关
- 当前已经引入独立待办表，支持待办组、子项以及多联系人/多事件关联

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

以下文档仍有参考价值，但不应作为当前产品事实源：

| 文档 | 性质 |
| ---- | ---- |
| `ATTACHMENT_STORAGE_REFACTOR_PLAN.md` | 附件存储改造历史方案 |
| `AI_INTEGRATION_ANALYSIS.md` | AI 能力路线分析（旧版，2025-07，已被 PRODUCT_STRATEGY_2026.md 取代） |

### 当前战略文档

| 文档 | 用途 |
| ---- | ---- |
| `PRODUCT_STRATEGY_2026.md` | 产品定位、AI 接入路线、数据入口策略、云同步决策（2026-03，当前事实源）|
| `CODE_REVIEW.md` | 代码审查记录 |

### 待执行实施计划

| 文档 | 内容 |
| ---- | ---- |
| `PLAN_SCHEMA_MIGRATION_V9.md` | Schema v9 迁移：为 8 张核心表添加 `deletedAt` 字段，预埋云同步软删除基础 |
| `PLAN_AI_INFRASTRUCTURE.md` | AI 基础设施：OpenAI 兼容 HTTP Provider + API key 存储 + 设置页 AI 配置区块 |
### 当前评审

| 文档 | 性质 |
| ---- | ---- |
| `UI_SCREENSHOT_REVIEW_2026_03_25.md` | 2026-03-25 基于截图补充的 UI 评审，聚焦局部体验问题与对应修改方案 |
| `HOME_WEEKLY_PLAN_TODO_ENHANCEMENT_PLAN_2026_03_25.md` | 2026-03-25 首页轻量周历与待办关联体验改造方案，包含设计决策与实施顺序 |
| `HOME_TIME_NODE_STRATEGY_AND_HOME_LAYOUT_PLAN_2026_03_26.md` | 2026-03-26 关于时间节点能力泛化判断、首页与日程页职责边界、以及首页新版展示结构的方案文档 |
| `HOME_UI_UX_DETAIL_PLAN_2026_03_26.md` | 2026-03-26 首页 UI/UX 细化规划，覆盖首屏结构、空状态、交互反馈、视觉层级与响应式行为 |
### 历史记录

以下文档用于回看过程，不应用来判断“现在项目是什么样”：

| 文档 | 性质 |
| ---- | ---- |
| `UI_REVIEW_2026_03_22.md` | 某一时点的 UI/UX 评审 |
| `UI_BEAUTIFICATION_PLAN.md` | 已完成 UI 美化工作的归档说明 |

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

1. 系统提醒闭环与跨平台通知
2. 联系人详情中的附件与里程碑体验深化
3. 联系人详情中的附件与里程碑体验深化
4. 节气等更多时间节点源扩展
5. 待办组与待办来源整合
