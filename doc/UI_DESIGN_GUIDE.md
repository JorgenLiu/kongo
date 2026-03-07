# Kongo UI/UX 设计规范

## 设计系统概述

本文档定义了Kongo应用的UI设计标准，确保整个应用的一致性和可用性。

---

## 视觉设计规范

### 1. 色彩系统

#### 主色板

| 色彩角色 | 颜色值 | 十六进制 | 用途 |
|---------|--------|---------|------|
| Primary | 蓝色 | #2196F3 | 主要操作、导航、强调 |
| Secondary | 青色 | #03DAC6 | 辅助操作、次要强调 |
| Tertiary | 紫色 | #7B1FA2 | 第三级强调 |
| Error | 红色 | #B00020 | 错误状态、危险操作 |
| Success | 绿色 | #4CAF50 | 成功状态、完成操作 |
| Warning | 橙色 | #FF9800 | 警告信息 |
| Info | 靛蓝 | #2962FF | 信息提示 |

#### 中性色

| 用途 | 亮色模式 | 深色模式 |
|------|---------|---------|
| Background | #FFFFFF | #121212 |
| Surface | #F5F5F5 | #1E1E1E |
| Surface Variant | #EEEEEE | #2C2C2C |
| Outline | #BDBDBD | #666666 |
| On Surface | #212121 | #FFFFFF |
| Disabled | #BDBDBD | #666666 |

#### 色彩使用规则

```
- Primary: 按钮、链接、选中状态
- Secondary: 次要按钮、辅助文本
- Error: 删除按钮、错误提示
- Success: 保存成功、操作完成
- Warning: 确认对话框、警告提示
```

#### 颜色代码示例（Flutter）

```dart
// 主题色定义
const Color kPrimaryColor = Color(0xFF2196F3);
const Color kSecondaryColor = Color(0xFF03DAC6);
const Color kErrorColor = Color(0xFFB00020);
const Color kSuccessColor = Color(0xFF4CAF50);
const Color kWarningColor = Color(0xFFFF9800);

// 中性色
const Color kBackgroundColor = Color(0xFFFFFFFF);
const Color kSurfaceColor = Color(0xFFF5F5F5);
const Color kOnSurfaceColor = Color(0xFF212121);
const Color kDisabledColor = Color(0xFFBDBDBD);
```

---

### 2. 排版系统

#### 字体

- **默认字体**: 
  - 中文: 系统默认（iOS: PingFang SC, Android: Noto Sans CJK）
  - 英文: Roboto
- **等宽字体**: Roboto Mono

#### 字号与样式定义

| 样式名 | 字号 | 字重 | 行高 | 字母间距 | 用途 |
|--------|------|------|------|---------|------|
| Display Large | 32sp | Bold (700) | 1.2 | 0 | 页面标题 |
| Display Medium | 28sp | Bold (700) | 1.2 | 0 | 二级标题 |
| Display Small | 24sp | Bold (700) | 1.2 | 0 | 卡片标题 |
| Headline | 20sp | Bold (700) | 1.3 | 0 | 列表项标题 |
| Title Large | 18sp | SemiBold (600) | 1.3 | 0 | 子标题 |
| Title Medium | 16sp | SemiBold (600) | 1.4 | 0 | 按钮文字 |
| Title Small | 14sp | SemiBold (600) | 1.4 | 0 | 标签文字 |
| Body Large | 16sp | Regular (400) | 1.5 | 0 | 正文大 |
| Body Medium | 14sp | Regular (400) | 1.5 | 0 | 正文默认 |
| Body Small | 12sp | Regular (400) | 1.5 | 0 | 正文小 |
| Label Large | 12sp | SemiBold (600) | 1.5 | 0.5 | 标签 |
| Label Medium | 11sp | SemiBold (600) | 1.5 | 0.5 | 标注 |
| Label Small | 10sp | SemiBold (600) | 1.5 | 0.5 | 最小标注 |

#### Typography配置（Flutter）

```dart
final TextTheme kTextTheme = TextTheme(
  displayLarge: const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
  ),
  displayMedium: const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
  ),
  // ... 其他样式
);
```

---

### 3. 间距系统

#### 间距基准单位: 4dp

| 尺寸 | 数值 | 倍数 | 用途 |
|------|------|------|------|
| XSmall | 4dp | 1x | 内部元素间距 |
| Small | 8dp | 2x | 列表项内间距 |
| Medium | 16dp | 4x | 卡片间距、页面边距 |
| Large | 24dp | 6x | 区域间距 |
| XLarge | 32dp | 8x | 屏幕顶部间距 |

#### 间距代码

```dart
// 间距常量
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

// 使用示例
const SizedBox(height: AppSpacing.md)
```

---

### 4. 圆角半径

| 类型 | 半径 | 用途 |
|------|------|------|
| None | 0 | 标准形状 |
| Extra Small | 4dp | 小按钮、图片 |
| Small | 8dp | 卡片边角 |
| Medium | 12dp | 对话框边角 |
| Large | 16dp | 大型组件 |
| Extra Large | 28dp | 超大组件 |

```dart
// 圆角常量
class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 28;
}
```

---

### 5. 阴影系统

#### 高度级别

```dart
// 阴影定义
class AppElevation {
  // 无阴影
  static const List<BoxShadow> none = [];
  
  // 浅阴影（卡片、输入框）
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];
  
  // 中等阴影（浮动按钮、弹窗）
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  // 深阴影（模态、菜单）
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
}
```

---

## 组件设计规范

### 1. 按钮 (Button)

#### 按钮类型

##### Filled Button（填充按钮）
- **背景色**: Primary Color
- **文字色**: White
- **最小高度**: 48dp
- **最小宽度**: 120dp
- **内边距**: Horizontal 24dp, Vertical 12dp

```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    minimumSize: const Size(120, 48),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
  ),
  onPressed: () {},
  child: const Text('确认'),
)
```

##### Outlined Button（边框按钮）
- **背景色**: Transparent
- **边框色**: Outline Color
- **边框宽度**: 1dp
- **高度**: 48dp

##### Text Button（文字按钮）
- **背景色**: Transparent
- **文字色**: Primary Color
- **无边框、无背景**

#### 按钮尺寸

| 尺寸 | 高度 | 最小宽度 | 场景 |
|------|------|---------|------|
| Large | 48dp | 120dp | 主要操作 |
| Medium | 40dp | 100dp | 普通操作 |
| Small | 32dp | 80dp | 辅助操作 |
| Extra Small | 24dp | 60dp | 标签操作 |

---

### 2. 输入框 (TextField)

#### 输入框样式

```dart
InputDecoration(
  hintText: '请输入名字',
  labelText: '名字',
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.sm),
  ),
  contentPadding: const EdgeInsets.all(AppSpacing.md),
  prefixIcon: const Icon(Icons.person),
  filled: true,
  fillColor: AppColors.surface,
)
```

#### 输入框状态

| 状态 | 背景色 | 边框色 | 文字色 |
|------|--------|--------|--------|
| Normal | Surface | Outline | On Surface |
| Focused | Surface | Primary | On Surface |
| Error | Error Light | Error | Error |
| Disabled | Disabled Light | Disabled | Disabled |

---

### 3. 卡片 (Card)

#### 卡片容器

```dart
Card(
  elevation: 1,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.sm),
  ),
  child: Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: // 内容
  ),
)
```

#### 卡片规范

- **背景色**: Surface
- **圆角**: 8dp
- **阴影**: sm级别
- **内边距**: 16dp
- **间距**: 卡片间距24dp

---

### 4. 列表项 (ListTile)

#### 标准列表项

```dart
ListTile(
  contentPadding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.sm,
  ),
  leading: // 左图标或头像
  title: // 主标题
  subtitle: // 副标题
  trailing: // 右操作区
  onTap: () {},
)
```

#### 列表项间距

- **水平内边距**: 16dp
- **竖直内边距**: 8dp
- **项目间距**: 0 (使用ListView分割线)

---

### 5. 对话框 (Dialog)

#### 对话框规范

```dart
AlertDialog(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
  title: // 标题
  content: // 内容
  actions: [
    // 按钮
  ],
)
```

#### 对话框尺寸

- **最小宽度**: 280dp
- **最大宽度**: 560dp
- **标题字号**: 20sp
- **内容字号**: 14sp
- **内边距**: 24dp

---

### 6. 浮动操作按钮 (FAB)

```dart
FloatingActionButton(
  backgroundColor: AppColors.primary,
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.lg),
  ),
  child: const Icon(Icons.add),
  onPressed: () {},
)
```

#### FAB规范

- **大小**: 56 x 56 dp
- **圆角**: 16dp
- **位置**: 右下角，距离16dp
- **阴影**: md级别

---

## 页面布局规范

### 1. AppBar

```dart
AppBar(
  title: const Text('页面标题'),
  backgroundColor: AppColors.primary,
  foregroundColor: Colors.white,
  elevation: 0,
  centerTitle: true,
  actions: [
    // 操作按钮
  ],
)
```

#### AppBar规范

- **高度**: 56 dp
- **标题对齐**: 中央
- **标题字号**: 20sp
- **颜色**: Primary Color
- **阴影**: 0 (无阴影)

### 2. SafeArea

所有屏幕都应使用SafeArea确保内容不被系统UI遮挡。

```dart
Scaffold(
  appBar: AppBar(),
  body: SafeArea(
    child: // 页面内容
  ),
)
```

### 3. 页面结构示例

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('标题'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 内容
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

---

## 交互规范

### 1. 触摸目标最小尺寸

- **最小**: 48 x 48 dp
- **推荐**: 56 x 56 dp

### 2. 反馈

#### 触摸反馈

所有可交互元素应提供触摸反馈：

```dart
InkWell(
  onTap: () {},
  splashColor: AppColors.primary.withOpacity(0.1),
  highlightColor: AppColors.primary.withOpacity(0.05),
  child: // 内容
)
```

#### 加载状态

```dart
Consumer<ContactProvider>(
  builder: (context, provider, _) {
    if (provider.loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return // 内容
  },
)
```

---

## 页面设计规范

### 1. 通讯录列表页面 (ContactsListScreen)

#### 页面结构

```
┌─────────────────────────────┐
│ AppBar: 通讯录               │
├─────────────────────────────┤
│ [搜索框]                     │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ [头像] 张三             │ │
│ │       13800000000      │ │
│ │       [家人][同事]     │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ [头像] 李四             │ │
│ │       13900000000      │ │
│ │       [朋友]           │ │
│ └─────────────────────────┘ │
│                             │
├─────────────────────────────┤
│              [+]             │
│         添加通讯人          │
└─────────────────────────────┘
```

#### 设计细节

- **搜索框**: 宽度100%，高度40dp，圆角8dp
- **列表项高度**: 72dp
- **头像尺寸**: 48 x 48 dp
- **标签显示**: 最多显示2个，超出则显示"+N"
- **FAB位置**: 右下角，距离16dp

---

### 2. 通讯人详情页 (ContactDetailScreen)

#### 页面结构

```
┌─────────────────────────────┐
│ AppBar: 返回 编辑 删除       │
├─────────────────────────────┤
│                             │
│       ┌─────────────┐       │
│       │  [大头像]  │       │
│       └─────────────┘       │
│         张三                │
│                             │
├─────────────────────────────┤
│ 联系方式                     │
│ 📞 13800000000             │
│ 📧 zhangsan@example.com    │
├─────────────────────────────┤
│ 标签                        │
│ [家人] [同事] [+]          │
├─────────────────────────────┤
│ 重要日期                     │
│ 🎂 生日: 1990-06-15        │
│ 💍 结婚纪念日: 2020-09-10  │
├─────────────────────────────┤
│ 备注                        │
│ 大学同学，经常联系           │
├─────────────────────────────┤
│ [删除通讯人]                 │
└─────────────────────────────┘
```

---

### 3. 标签管理页面 (TagsScreen)

#### 页面结构

```
┌─────────────────────────────┐
│ AppBar: 标签管理             │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ ⚪ 家人         编辑 删除 │ │
│ │     5个通讯人           │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ ⚪ 同事         编辑 删除 │ │
│ │     3个通讯人           │ │
│ └─────────────────────────┘ │
│                             │
├─────────────────────────────┤
│              [+]             │
│          新建标签            │
└─────────────────────────────┘
```

---

## 响应式设计

### 屏幕尺寸断点

| 设备类型 | 宽度范围 | 布局 |
|---------|---------|------|
| 手机(竖) | < 600 dp | 单列 |
| 手机(横) | 600-840 dp | 单列/两列 |
| 平板 | ≥ 840 dp | 两列/三列 |

### 布局适配

```dart
double getMainAxisCount(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < 600) {
    return 1; // 单列
  } else if (width < 840) {
    return 2; // 两列
  } else {
    return 3; // 三列
  }
}
```

---

## 深色模式支持

所有颜色应支持深色模式，使用ThemeData的brightness属性：

```dart
ThemeData.dark().copyWith(
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.darkBackground,
)
```

---

## 无障碍设计 (Accessibility)

### 1. 最小字号

- **正文**: 14sp 最小
- **按钮**: 12sp 最小

### 2. 对比度

- **大文本**: 3:1 最小
- **正常文本**: 4.5:1 最小
- **UI组件**: 3:1 最小

### 3. 语义标签

```dart
// 使用Semantics提供屏幕阅读器支持
Semantics(
  label: '删除通讯人张三',
  button: true,
  enabled: true,
  child: IconButton(
    icon: const Icon(Icons.delete),
    onPressed: () {},
  ),
)
```

---

## 设计资源

### 图标规范

- **来源**: Flutter Material Icons
- **大小**: 24dp (默认), 18dp (小), 32dp (大)
- **颜色**: On Surface或Primary

### 插图

- **风格**: 简洁现代
- **配色**: 与品牌色协调

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0 | 2026-03-06 | 初始设计规范 |

---

**最后更新**: 2026年3月6日

