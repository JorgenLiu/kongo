import 'package:flutter/material.dart';

/// 应用颜色常量
class AppColors {
  // 主色板
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color tertiary = Color(0xFF7B1FA2);
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2962FF);

  // 中性色 - 亮色模式
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color surfaceVariant = Color(0xFFEEEEEE);
  static const Color outline = Color(0xFFBDBDBD);
  static const Color onSurface = Color(0xFF212121);
  static const Color disabled = Color(0xFFBDBDBD);

  // 深色模式
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2C2C2C);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  static const Color disabledDark = Color(0xFF666666);
}
