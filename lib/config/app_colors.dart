import 'package:flutter/material.dart';

/// 应用颜色常量
class AppColors {
  // Agenda-inspired accent palette
  static const Color primary = Color(0xFFB17A14);
  static const Color secondary = Color(0xFF8A6722);
  static const Color tertiary = Color(0xFF5F4C2B);
  static const Color error = Color(0xFFB04A3F);
  static const Color success = Color(0xFF4F7A54);
  static const Color warning = Color(0xFFD4882A);
  static const Color info = Color(0xFF5A8A7A);

  // Light theme neutrals
  static const Color background = Color(0xFFF3F1EB);
  static const Color surface = Color(0xFFFBF8F3);
  static const Color surfaceVariant = Color(0xFFE6E0D5);
  static const Color outline = Color(0xFF665E52);
  static const Color onSurface = Color(0xFF1F1B16);
  static const Color disabled = Color(0xFF9E9688);
  static const Color cardBorder = Color(0xFFC5BDA8);
  static const Color accentSoft = Color(0xFFF2E2B3);

  // Dark theme neutrals — 深色底盘，用空间代替边框
  static const Color backgroundDark = Color(0xFF0E0C09);   // 更深的暖黑底色
  static const Color surfaceDark = Color(0xFF1E1B17);       // 与背景拉开层次
  static const Color surfaceVariantDark = Color(0xFF2D2820); // 进一步抬高的层级
  static const Color outlineDark = Color(0xFF7A7268);
  static const Color onSurfaceDark = Color(0xFFEDE5D4);     // 暖白，减少刺眼感
  static const Color disabledDark = Color(0xFF6E6559);
  static const Color cardBorderDark = Color(0xFF2A2520);    // 极其克制，几乎不可见
  static const Color accentSoftDark = Color(0xFF382D13);
}
