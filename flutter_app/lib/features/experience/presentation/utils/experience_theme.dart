import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/experience_colors.dart';
import '../../domain/entities/app_experience.dart';

/// Applies guardian plum or organisation teal to [ColorScheme.primary] for routed UI.
///
/// Organisation routes also remap component themes that hardcode guardian plum in
/// [AppTheme.lightTheme] so `/o/**` shell surfaces stay teal-only (D-desk-S8).
ThemeData themeForAppExperience(ThemeData base, AppExperience experience) {
  final isOrg = experience == AppExperience.organization;
  final xp = base.extension<ExperienceColors>() ?? ExperienceColors.light;
  final primary = xp.primaryFor(organization: isOrg);
  final onPrimary = xp.onPrimaryFor(organization: isOrg);
  final primaryContainer = isOrg ? xp.organizationLight : xp.petCareLight;
  final onPrimaryContainer = isOrg ? xp.organizationPrimary : xp.petCareActive;

  final colorScheme = base.colorScheme.copyWith(
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
  );

  if (!isOrg) {
    return base.copyWith(colorScheme: colorScheme);
  }

  return base.copyWith(
    colorScheme: colorScheme,
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
    ),
    floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
      backgroundColor: primary,
      foregroundColor: onPrimary,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: (base.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
        backgroundColor: WidgetStateProperty.all(primary),
        foregroundColor: WidgetStateProperty.all(onPrimary),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: (base.textButtonTheme.style ?? const ButtonStyle()).copyWith(
        foregroundColor: WidgetStateProperty.all(primary),
      ),
    ),
    tabBarTheme: base.tabBarTheme.copyWith(
      labelColor: primary,
      indicatorColor: primary,
    ),
    progressIndicatorTheme: base.progressIndicatorTheme.copyWith(color: primary),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return null;
      }),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return AppColorTokens.muted;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return onPrimary;
        }
        return AppColorTokens.surface;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return AppColorTokens.border;
      }),
    ),
  );
}
