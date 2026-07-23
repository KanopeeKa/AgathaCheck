import 'package:flutter/material.dart';

import 'app_color_tokens.dart';
import 'experience_colors.dart';

/// Material 3 theme — warm neutrals, guardian plum default primary.
///
/// Organisation teal and mode-specific tokens live in [ExperienceColors].
/// See `docs/design/tokens.md`.
class AppTheme {
  AppTheme._();

  // Legacy org widget aliases → organisation token family (Phase 1 migrates call sites).
  static const Color orgBlue = AppColorTokens.organizationLight;
  static const Color orgBlueDarker = AppColorTokens.organizationSoft;
  static const Color orgIconBg = AppColorTokens.organizationSoft;
  static const Color orgIconFg = AppColorTokens.organizationPrimary;
  static const Color orgCharityBg = AppColorTokens.organizationSoft;
  static const Color orgCharityFg = AppColorTokens.organizationPrimary;
  static const Color orgBadgeBg = AppColorTokens.organizationLight;
  static const Color orgBadgeFg = AppColorTokens.organizationPrimary;
  static const Color orgCharityBadgeBg = AppColorTokens.organizationLight;
  static const Color orgCharityBadgeFg = AppColorTokens.organizationPrimary;
  static const Color orgSuperUserBg = AppColorTokens.warmAccentLight;
  static const Color orgSuperUserFg = Color(0xFF8B5E4A);
  static const Color orgChipBg = AppColorTokens.organizationLight;
  static const Color orgChipFg = AppColorTokens.organizationPrimary;

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColorTokens.guardianPrimary,
      onPrimary: AppColorTokens.inverse,
      primaryContainer: AppColorTokens.guardianLight,
      onPrimaryContainer: AppColorTokens.guardianActive,
      secondary: AppColorTokens.organizationPrimary,
      onSecondary: AppColorTokens.inverse,
      secondaryContainer: AppColorTokens.organizationLight,
      onSecondaryContainer: AppColorTokens.organizationActive,
      tertiary: AppColorTokens.warmAccent,
      onTertiary: AppColorTokens.heading,
      tertiaryContainer: AppColorTokens.warmAccentLight,
      onTertiaryContainer: AppColorTokens.heading,
      error: AppColorTokens.danger,
      onError: AppColorTokens.inverse,
      surface: AppColorTokens.surface,
      onSurface: AppColorTokens.body,
      onSurfaceVariant: AppColorTokens.muted,
      outline: AppColorTokens.border,
      outlineVariant: AppColorTokens.borderStrong,
      shadow: Color(0x142D3338),
      surfaceContainerHighest: AppColorTokens.surfaceAlt,
      surfaceContainerHigh: AppColorTokens.surfaceAlt,
      surfaceContainer: AppColorTokens.surface,
      surfaceContainerLow: AppColorTokens.surface,
      surfaceContainerLowest: AppColorTokens.background,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColorTokens.background,
      extensions: const [ExperienceColors.light],
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColorTokens.surface,
        foregroundColor: AppColorTokens.heading,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColorTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColorTokens.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorTokens.surface,
        labelStyle: const TextStyle(color: AppColorTokens.body),
        hintStyle: const TextStyle(color: AppColorTokens.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColorTokens.guardianPrimary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorTokens.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColorTokens.guardianPrimary,
        foregroundColor: AppColorTokens.inverse,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColorTokens.guardianPrimary,
          foregroundColor: AppColorTokens.inverse,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AppColorTokens.guardianPrimary,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColorTokens.guardianPrimary,
        unselectedLabelColor: AppColorTokens.muted,
        indicatorColor: AppColorTokens.guardianPrimary,
      ),
      dividerTheme: const DividerThemeData(color: AppColorTokens.border),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColorTokens.heading,
        contentTextStyle: const TextStyle(color: AppColorTokens.inverse),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColorTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColorTokens.heading,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColorTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColorTokens.borderStrong,
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 12,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColorTokens.surfaceAlt,
        labelStyle: const TextStyle(color: AppColorTokens.body),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColorTokens.guardianPrimary,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorTokens.guardianPrimary;
          }
          return null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorTokens.guardianPrimary;
          }
          return AppColorTokens.muted;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorTokens.inverse;
          }
          return AppColorTokens.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorTokens.guardianPrimary;
          }
          return AppColorTokens.border;
        }),
      ),
    );
  }
}
