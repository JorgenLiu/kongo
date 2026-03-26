# Kongo UI 设计指南

## 文档范围

本文档描述当前已经落地、并应继续遵守的 UI 事实。

主要对应：

- `lib/config/app_colors.dart`
- `lib/config/app_constants.dart`
- `lib/config/app_theme.dart`
- 当前日历、列表、工作台与详情页的已落地交互模式

## 当前视觉方向

产品当前采用 Agenda 风格的暖棕色工作台语气。

关键词：

- 沉稳
- 文档感
- 工具台
- 高信息密度的桌面工作区

## 色彩系统

### 主色板

| 角色 | 颜色值 |
| ---- | ---- |
| Primary | `#B17A14` |
| Secondary | `#8A6722` |
| Tertiary | `#5F4C2B` |
| Error | `#B04A3F` |
| Success | `#4F7A54` |
| Warning | `#C18A1C` |
| Info | `#8F6B2A` |

### 亮色中性色

| 角色 | 颜色值 |
| ---- | ---- |
| Background | `#F3F1EB` |
| Surface | `#FBF8F3` |
| Surface Variant | `#E6E0D5` |
| Outline | `#7F7669` |
| On Surface | `#1F1B16` |
| Disabled | `#9E9688` |
| Card Border | `#C5BDA8` |
| Accent Soft | `#F2E2B3` |

### 深色中性色

| 角色 | 颜色值 |
| ---- | ---- |
| Background | `#13110F` |
| Surface | `#1A1714` |
| Surface Variant | `#28231D` |
| Outline | `#8A8074` |
| On Surface | `#F5EFE4` |
| Disabled | `#6E6559` |
| Card Border | `#4A4235` |
| Accent Soft | `#382D13` |

## 主题约束

- 使用 Material 3
- 同时维护亮色与深色主题
- Card 使用轻微阴影与边框建立层次，不再是纯平卡片
- FilledButton、OutlinedButton、TextButton 的层级已拉开
- 输入框使用填充背景与中等圆角
- Focus 态与 hover 态应有明确视觉反馈

## 设计 Token

### 间距

| Token | 数值 |
| ---- | ---- |
| `AppSpacing.xs` | 4 |
| `AppSpacing.sm` | 8 |
| `AppSpacing.md` | 16 |
| `AppSpacing.lg` | 24 |
| `AppSpacing.xl` | 32 |

### 圆角

| Token | 数值 |
| ---- | ---- |
| `AppRadius.xs` | 4 |
| `AppRadius.sm` | 8 |
| `AppRadius.md` | 12 |
| `AppRadius.lg` | 16 |

### 字号

当前已落地的关键 token：

- `displayLarge = 32`
- `displayMedium = 28`
- `displaySmall = 24`
- `headline = 20`
- `titleLarge = 18`
- `titleMedium = 16`
- `titleSmall = 14`
- `bodyLarge = 15`
- `bodyMedium = 14`
- `bodySmall = 12`
- `labelLarge = 11`

### 响应式断点

| Token | 数值 | 作用 |
| ---- | ---- | ---- |
| `desktopShell` | 1000 | Web 端桌面壳切换 |
| `scheduleCompact` | 760 | 日程头部紧凑模式 |
| `monthCalendarCompact` | 900 | 月历紧凑模式 |
| `weekCalendarScroll` | 860 | 周历切换横向滚动 |

## 当前交互事实

### 桌面端能力

以下能力已落地，不应再写成“待做”：

1. 全局快捷键
2. 页面转场
3. 联系人 / 事件列表 hover 快捷操作
4. 联系人 / 事件 / 总结 / 标签 / 文件库主要右键菜单
5. 核心列表卡片基础 Semantics

### 日历

- 当前支持周历、月历、时间线三类视图
- 周历 / 月历已支持展示联系人重要日期节点、公共纪念日节点与营销节点
- 时间节点当前与日程分层展示，不混用同一视觉语义
- 当前已提供时间节点类别开关，入口位于设置中心
- 当前已接入营销节点；尚未接入节气、世界纪念日等更多节点源

### 页面组织

#### 列表页

优先结构：

1. 页头
2. 搜索 / 过滤条
3. 计数或辅助信息
4. 列表 / 空态 / 错误态

#### 详情页

优先结构：

1. Header card
2. 信息 section
3. 关系 / 附件 / 聚合 section

#### 工作台页

多数页面已统一使用 `WorkbenchPageHeader` 作为头部骨架。

#### 待办页

- 一级导航中已包含待办入口
- 待办页当前采用“组列表 + 组详情”结构
- 组详情中按一级项 / 子项两层展示，并通过弹窗编辑关联联系人与事件

## 当前已知 UI 缺口

1. 可访问性语义尚未覆盖全部表单、导航与复杂交互
2. 设置中心已成型，但偏好持久化与更完整设置项仍不足（AI 配置、语言、通知策略等）
3. 全局检索尚未纳入附件维度
4. 日历时间节点仍待扩展节气等更多节点源
5. 首页信息层级需重构（详见 `HOME_UI_UX_DETAIL_PLAN_2026_03_26.md`）

## 文档使用约定

如果设计设想与代码实现冲突：

1. 先以当前代码生效样式为准
2. 再更新本文档或代码
3. 不保留两套互相矛盾的定义
