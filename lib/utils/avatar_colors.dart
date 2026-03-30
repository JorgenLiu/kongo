import 'package:flutter/material.dart';

/// 联系人头像颜色系统 — 基于名字哈希生成一致的渐变材质
///
/// 5 组暖金色阶，与主题色 primary (#B17A14) 同族，
/// 保证同一名字每次显示相同颜色，视觉上统一内敛。
class AvatarColors {
  // 5 组暗色模式暖金渐变
  static const List<List<Color>> _darkGradients = [
    [Color(0xFF3A2E12), Color(0xFF251C08)], // 深琥珀
    [Color(0xFF2E2618), Color(0xFF1C180E)], // 暖棕
    [Color(0xFF33280D), Color(0xFF201808)], // 焦糖棕
    [Color(0xFF2A2A1A), Color(0xFF1A1A0E)], // 暗麦穗
    [Color(0xFF2E2010), Color(0xFF1E1508)], // 烟熏金
  ];

  // 5 组亮色模式暖金渐变
  static const List<List<Color>> _lightGradients = [
    [Color(0xFFF2E2C0), Color(0xFFE8D4A6)], // 浅金
    [Color(0xFFECD8B8), Color(0xFFDECA9C)], // 麦穗
    [Color(0xFFF0DEB0), Color(0xFFE2CC94)], // 浅琥珀
    [Color(0xFFE8E0C8), Color(0xFFD8D0B2)], // 淡米
    [Color(0xFFF0D898), Color(0xFFE2C880)], // 暖杏
  ];

  // 暗色模式 — 暖金系高亮文字
  static const List<Color> _darkTextColors = [
    Color(0xFFE8C87B), // 金
    Color(0xFFDCBC72), // 暖金
    Color(0xFFE4C268), // 焦糖金
    Color(0xFFD4BC80), // 麦穗
    Color(0xFFE0C070), // 杏金
  ];

  // 亮色模式 — 深金系文字
  static const List<Color> _lightTextColors = [
    Color(0xFF6B5020), // 深琥珀
    Color(0xFF5C4418), // 暖棕
    Color(0xFF664E18), // 焦糖
    Color(0xFF504828), // 暗麦穗
    Color(0xFF504010), // 深金
  ];

  /// 根据名字字符串生成一致的索引（0-4）
  static int _indexFrom(String name) {
    if (name.isEmpty) return 0;
    var hash = 0;
    for (final c in name.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF;
    }
    return hash % _darkGradients.length;
  }

  /// 根据亮暗模式自动选择头像渐变
  static LinearGradient gradient(String name, {required Brightness brightness}) {
    final idx = _indexFrom(name);
    final colors = brightness == Brightness.dark
        ? _darkGradients[idx]
        : _lightGradients[idx];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  /// 根据亮暗模式自动选择头像文字颜色
  static Color textColor(String name, {required Brightness brightness}) {
    final idx = _indexFrom(name);
    return brightness == Brightness.dark
        ? _darkTextColors[idx]
        : _lightTextColors[idx];
  }
}
