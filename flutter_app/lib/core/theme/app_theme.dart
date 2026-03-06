import 'package:flutter/material.dart';

/// Provides the application's Material 3 theme configuration.
///
/// Uses a purple seed color to generate a cohesive color scheme
/// and configures component themes for cards, inputs, buttons,
/// tabs, and more.
class AppTheme {
  AppTheme._();

  static const Color orgBlue = Color(0xFFE8F0FE);
  static const Color orgBlueDarker = Color(0xFFD3E3FD);

  static const Color orgIconBg = Color(0xFFBBDEFB);
  static const Color orgIconFg = Color(0xFF1565C0);
  static const Color orgCharityBg = Color(0xFFB2DFDB);
  static const Color orgCharityFg = Color(0xFF00695C);
  static const Color orgBadgeBg = Color(0xFFE3F2FD);
  static const Color orgBadgeFg = Color(0xFF1565C0);
  static const Color orgCharityBadgeBg = Color(0xFFE0F2F1);
  static const Color orgCharityBadgeFg = Color(0xFF00695C);
  static const Color orgSuperUserBg = Color(0xFFFFF8E1);
  static const Color orgSuperUserFg = Color(0xFFE65100);
  static const Color orgChipBg = Color(0xFFE3F2FD);
  static const Color orgChipFg = Color(0xFF1565C0);

  /// The light [ThemeData] for the application.
  ///
  /// Built from a [ColorScheme] seeded with purple, this theme
  /// configures Material 3 components including app bars, cards,
  /// input fields, floating action buttons, and tab bars.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withAlpha(80),
      ),
    );
  }
}
