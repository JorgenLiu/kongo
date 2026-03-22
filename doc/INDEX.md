# Kongo 文档导航

本文档是项目文档入口，优先说明当前代码真实状态，以及每份文档各自负责回答什么问题。

## 当前项目状态

### 已打通的能力
- 联系人 CRUD 与关键字搜索
- 标签管理与联系人打标
- 事件 CRUD、多参与人、事件类型、关键字搜索、事件类型过滤
- 每日总结 CRUD、按日期唯一约束、关键字搜索、行动项提取
- 附件保存、本地打开、关联事件/总结、解绑与删除
- 文件库总览
- 跨联系人 / 事件 / 每日总结的全局检索
- 读侧聚合与页面级 provider 模式
- 结构化错误与 SQLite FFI 测试基线

### 当前导航与入口
- 一级导航：日程、通讯录、检索、总结、设置
- 次级入口：标签管理、文件库
- 联系人详情中的附件入口仍为轻量提示，不是完整联系人附件模块页

### 重要校准
- 当前总结模型是 `DailySummary`，数据库表为 `daily_summaries`
- 历史 `event_summaries` 表仅用于旧数据迁移，不再是当前主读写模型
- 当前事件运行时模型不再暴露 `status`
- 数据库 `events.status` 仍保留，用于兼容旧版本与迁移路径
- 当前已验证平台只有 macOS；iOS / Windows 仅有平台工程

## 文档索引

| 文档 | 作用 |
| ---- | ---- |
| `INDEX.md` | 文档入口、项目现状、阅读顺序 |
| `PROJECT_PLAN.md` | 产品定位、当前边界、下一阶段路线图 |
| `DATABASE_DESIGN.md` | SQLite schema、迁移、兼容列与索引 |
| `API_SPECIFICATION.md` | 异常模型、Repository / Service / Read Service / Provider 契约 |
| `UI_DESIGN_GUIDE.md` | 当前生效的颜色、间距、主题与页面交互规范 |
| `DEVELOPMENT_GUIDE.md` | 环境搭建、分层架构、开发流程与测试方式 |
| `UI_REVIEW_2026_03_22.md` | 2026-03-22 时点的 UI/UX 评审记录，不作为产品事实源 |

## 建议阅读顺序

### 了解项目全貌
1. `PROJECT_PLAN.md`
2. `DEVELOPMENT_GUIDE.md`
3. `UI_DESIGN_GUIDE.md`

### 改业务与数据
1. `DATABASE_DESIGN.md`
2. `API_SPECIFICATION.md`
3. `DEVELOPMENT_GUIDE.md`

### 改页面与交互
1. `UI_DESIGN_GUIDE.md`
2. `DEVELOPMENT_GUIDE.md`
3. `UI_REVIEW_2026_03_22.md`

## 当前推荐的下一步关注点

1. 系统提醒闭环与跨平台发布身份准备
2. 文件库与联系人详情模块深化
3. 桌面端快捷键、右键菜单、悬停反馈等原生体验补齐
4. 全局检索继续扩展到附件维度