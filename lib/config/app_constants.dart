/// 应用间距常量
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// 应用圆角常量
class AppRadius {
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
}

/// 字体大小常量
class AppFontSize {
  static const double displayLarge = 32;
  static const double displayMedium = 28;
  static const double displaySmall = 24;
  static const double headline = 20;
  static const double titleLarge = 18;
  static const double titleMedium = 16;
  static const double titleSmall = 14;
  static const double bodyLarge = 16;
  static const double bodyMedium = 14;
  static const double bodySmall = 12;
  static const double labelLarge = 12;
  static const double labelMedium = 11;
  static const double labelSmall = 10;
}

/// 响应式断点
class AppBreakpoints {
  /// Web 端切换桌面/移动布局
  static const double desktopShell = 1000;

  /// 日程头部紧凑模式
  static const double scheduleCompact = 760;

  /// 月历紧凑模式
  static const double monthCalendarCompact = 900;

  /// 周日历从网格切为横向滚动
  static const double weekCalendarScroll = 860;
}

/// 全局尺寸 Token
class AppDimensions {
  /// 侧边栏展开宽度
  static const double sidebarWidth = 228;

  /// 侧边栏折叠宽度（仅图标）
  static const double sidebarCollapsedWidth = 72;

  /// NavigationRail 最小展开宽度
  static const double sidebarNavMinWidth = 196;

  /// 表单最大宽度（联系人/事件/总结统一）
  static const double formMaxWidth = 780;

  /// 联系人头像尺寸
  static const double contactAvatarSize = 52;

  /// 事件状态图标容器尺寸
  static const double statusIconSize = 42;

  /// 文件卡片图标容器宽高
  static const double fileIconWidth = 54;
  static const double fileIconHeight = 64;

  /// 周日历卡片宽度（窄屏横向滚动）
  static const double weekDayCardWidth = 188;

  /// 周日历横向滚动高度
  static const double weekCalendarScrollHeight = 236;

  /// 周日历每天最大事件预览数
  static const int maxWeekDayEventPreview = 3;
}

/// 标准化透明度常量
class AppOpacity {
  /// 微弱 — 背景填充
  static const double subtle = 0.08;

  /// 浅色 — 状态色背景
  static const double light = 0.14;

  /// 中等 — 选中态/边框
  static const double medium = 0.30;

  /// 半高不透明 — 元数据药丸背景
  static const double elevated = 0.45;

  /// 半透明 — 选中态覆盖
  static const double half = 0.55;
}




