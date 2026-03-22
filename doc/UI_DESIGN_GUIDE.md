# Kongo UI 设计指南

## 说明

本文档以当前已落地代码为准，主要对应：

- `lib/config/app_colors.dart`
- `lib/config/app_constants.dart`
- `lib/config/app_theme.dart`

如果设计设想与代码实现冲突，应先更新本文档或代码，不保留两套互相矛盾的定义。

## 视觉方向

当前产品采用 Agenda 风格的暖棕色工作台语气，而不是早期蓝青色方案。

关键词：
- 沉稳
- 桌面感
- 文档感
- 信息工作台

## 色彩系统

### 主色板

| 角色 | 颜色值 | 用途 |
| ---- | ---- | ---- |
| Primary | `#B17A14` | 主要操作、导航强调、选中态 |
| Secondary | `#8A6722` | 次级强调 |
| Tertiary | `#5F4C2B` | 第三级强调 |
| Error | `#B04A3F` | 错误与危险操作 |
| Success | `#4F7A54` | 成功状态 |
| Warning | `#C18A1C` | 警示与提醒语义 |
| Info | `#8F6B2A` | 信息提示 |

### 亮色中性色

| 角色 | 颜色值 |
| ---- | ---- |
| Background | `#F3F1EB` |
| Surface | `#FBF8F3` |
| Surface Variant | `#E6E0D5` |
| Outline | `#7F7669` |
| On Surface | `#1F1B16` |
| Disabled | `#C2BBAD` |
| Card Border | `#D8D1C3` |
| Accent Soft | `#F2E2B3` |

### 深色中性色

| 角色 | 颜色值 |
| ---- | ---- |
| Background | `#13110F` |
| Surface | `#1A1714` |
| Surface Variant | `#28231D` |
| Outline | `#8A8074` |
| On Surface | `#F5EFE4` |
| Disabled | `#60584E` |
| Card Border | `#393329` |
| Accent Soft | `#382D13` |

## 主题实现约束

### ThemeData
- 使用 Material 3
- 同时维护亮色与深色主题
- `ThemeMode.system`

### 组件风格
- Card 默认无阴影，依赖边框与浅底色建立层次
- NavigationRail / NavigationBar 使用柔和选中底色
- FilledButton 高度统一到 42
- 输入框使用填充背景与中等圆角

## 尺寸 Token

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

### 响应式断点

当前已集中到 `AppBreakpoints`：

| Token | 数值 | 作用 |
| ---- | ---- | ---- |
| `desktopShell` | 1000 | Web 端桌面壳切换 |
| `scheduleCompact` | 760 | 日程头部紧凑模式 |
| `monthCalendarCompact` | 900 | 月历紧凑模式 |
| `weekCalendarScroll` | 860 | 周历切换横向滚动 |

### 全局尺寸

| Token | 数值 | 用途 |
| ---- | ---- | ---- |
| `sidebarWidth` | 228 | 侧边栏展开宽度 |
| `sidebarCollapsedWidth` | 72 | 侧边栏折叠宽度 |
| `sidebarNavMinWidth` | 196 | NavigationRail 最小展开宽度 |
| `formMaxWidth` | 780 | 表单最大宽度 |
| `contactAvatarSize` | 52 | 联系人头像 |
| `weekDayCardWidth` | 188 | 周历日卡宽度 |
| `weekCalendarScrollHeight` | 236 | 周历横向滚动高度 |

## 当前导航设计

### 一级导航
- 日程
- 通讯录
- 检索
- 总结
- 设置

### 次级页面
- 标签管理
- 文件库

设计原则：
- 高频聚焦在主壳导航
- 辅助模块通过次级入口进入
- screen 保持为编排层，交互动作尽量下沉到 action 文件与 section widget

## 页面规范

### Workbench 页头
多数工作台页使用 `WorkbenchPageHeader`：

- eyebrow
- title
- 可选 description
- 可选 trailing action

### 列表页
优先组成：

1. 页头
2. 搜索栏
3. 辅助计数或过滤栏
4. 列表内容 / 空态 / 错误态

### 详情页
优先组成：

1. Header card
2. 信息 section
3. 关系 / 附件 / 聚合 section

### 状态反馈
统一优先复用：
- `ErrorState`
- `EmptyState`
- `DetailSkeleton`

## 搜索结果规范

当前全局检索与事件检索已具备：

- 命中词高亮
- 结果排序
- 分区展示联系人 / 事件 / 总结

后续扩展时要求：

1. 高亮行为一致
2. 排序策略放在 provider，不放在 widget
3. 搜索结果卡片不复用与语义不匹配的通用列表卡

## 当前已知 UI 缺口

以下问题已被确认，但尚未全部实现：

1. 桌面端快捷键不足
2. 右键菜单不足
3. Hover 态覆盖不完整
4. 设置页仍较轻量
5. 文件库仍偏基础

这些属于后续迭代任务，不应误写为“已完成”。