import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_constants.dart';

/// 应用主题配置
class AppTheme {
  static final ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    scheme: _lightScheme,
    borderColor: AppColors.cardBorder,
    accentSoft: AppColors.accentSoft,
  );

  static final ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    scheme: _darkScheme,
    borderColor: AppColors.cardBorderDark,
    accentSoft: AppColors.accentSoftDark,
  );

  static final String? _titleFontFamily =
      defaultTargetPlatform == TargetPlatform.macOS
          ? '.SF Pro Rounded'
          : null;

  static final TextTheme _baseTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: AppFontSize.displayLarge,
      fontWeight: FontWeight.bold,
      height: 1.2,
      fontFamily: _titleFontFamily,
    ),
    displayMedium: TextStyle(
      fontSize: AppFontSize.displayMedium,
      fontWeight: FontWeight.bold,
      height: 1.2,
      fontFamily: _titleFontFamily,
    ),
    displaySmall: TextStyle(
      fontSize: AppFontSize.displaySmall,
      fontWeight: FontWeight.bold,
      height: 1.2,
      fontFamily: _titleFontFamily,
    ),
    headlineSmall: TextStyle(
      fontSize: AppFontSize.headline,
      fontWeight: FontWeight.w800,
      height: 1.25,
      fontFamily: _titleFontFamily,
    ),
    titleLarge: TextStyle(
      fontSize: AppFontSize.titleLarge,
      fontWeight: FontWeight.w700,
      height: 1.25,
      fontFamily: _titleFontFamily,
    ),
    titleMedium: TextStyle(
      fontSize: AppFontSize.titleMedium,
      fontWeight: FontWeight.w600,
      height: 1.35,
      fontFamily: _titleFontFamily,
    ),
    titleSmall: TextStyle(
      fontSize: AppFontSize.titleSmall,
      fontWeight: FontWeight.w600,
      height: 1.35,
      fontFamily: _titleFontFamily,
    ),
    bodyLarge: TextStyle(
      fontSize: AppFontSize.bodyLarge,
      fontWeight: FontWeight.w400,
      height: 1.45,
    ),
    bodyMedium: TextStyle(
      fontSize: AppFontSize.bodyMedium,
      fontWeight: FontWeight.w400,
      height: 1.45,
    ),
    bodySmall: TextStyle(
      fontSize: AppFontSize.bodySmall,
      fontWeight: FontWeight.w400,
      height: 1.45,
    ),
    labelLarge: TextStyle(
      fontSize: AppFontSize.labelLarge,
      fontWeight: FontWeight.w700,
      height: 1.35,
      letterSpacing: 0.6,
    ),
  );

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.accentSoft,
    onPrimaryContainer: AppColors.onSurface,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFEADDBA),
    onSecondaryContainer: AppColors.onSurface,
    tertiary: AppColors.tertiary,
    onTertiary: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerLow: const Color(0xFFFFFCF7),
    surfaceContainerHighest: AppColors.surfaceVariant,
    outline: AppColors.cardBorder,
    outlineVariant: AppColors.surfaceVariant,
    shadow: const Color(0x14000000),
    surfaceTint: AppColors.primary,
    error: AppColors.error,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFFB8892F),
    onPrimary: const Color(0xFF2B2112),
    primaryContainer: AppColors.accentSoftDark,
    onPrimaryContainer: AppColors.onSurfaceDark,
    secondary: const Color(0xFFC69D46),
    onSecondary: const Color(0xFF281F11),
    secondaryContainer: const Color(0xFF3A311D),
    onSecondaryContainer: AppColors.onSurfaceDark,
    tertiary: const Color(0xFFB6945C),
    onTertiary: const Color(0xFF211A11),
    surface: AppColors.surfaceDark,
    onSurface: AppColors.onSurfaceDark,
    surfaceContainerLow: const Color(0xFF14110E),
    surfaceContainerHighest: AppColors.surfaceVariantDark,
    outline: AppColors.cardBorderDark,
    outlineVariant: const Color(0xFF2A251F),
    shadow: const Color(0x33000000),
    surfaceTint: const Color(0xFFB8892F),
    error: const Color(0xFFD07A72),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color borderColor,
    required Color accentSoft,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      primaryColor: scheme.primary,
      scaffoldBackgroundColor: brightness == Brightness.light ? AppColors.background : AppColors.backgroundDark,
      canvasColor: scheme.surface,
      textTheme: _baseTextTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    );

    final borderSide = BorderSide(color: borderColor);

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: base.scaffoldBackgroundColor,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: scheme.shadow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: borderSide,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          elevation: 1,
          shadowColor: scheme.primary.withValues(alpha: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(0, 42),
          side: BorderSide(color: brightness == Brightness.light ? AppColors.outline : AppColors.outlineDark),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        hoverElevation: 0,
        focusElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: AppColors.outline),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: borderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: borderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: scheme.primary,
            width: 2.0,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: accentSoft,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: base.scaffoldBackgroundColor,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: AppColors.outline),
        selectedLabelTextStyle: base.textTheme.labelLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: base.textTheme.labelLarge?.copyWith(
          color: AppColors.outline,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: borderSide,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return brightness == Brightness.light ? AppColors.disabled : AppColors.disabledDark;
          }
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimary;
          }
          return scheme.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return borderColor.withValues(alpha: 0.4);
          }
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: 0.2);
          }
          return borderColor;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
            return scheme.primary.withValues(alpha: 0.12);
          }
          return null;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: borderSide,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surface,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: borderSide,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: accentSoft,
        disabledColor: brightness == Brightness.light ? AppColors.disabled : AppColors.disabledDark,
        side: borderSide,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        labelStyle: base.textTheme.bodySmall,
        secondaryLabelStyle: base.textTheme.bodySmall?.copyWith(color: scheme.primary),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurface,
        textColor: scheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          focusColor: scheme.primary.withValues(alpha: 0.15),
          hoverColor: scheme.primary.withValues(alpha: 0.10),
        ),
      ),
    );
  }
}
