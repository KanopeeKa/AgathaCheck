import 'package:flutter/material.dart';

import 'app_color_tokens.dart';

/// Experience-aware colors (guardian plum vs organisation teal).
///
/// Registered on [ThemeData.extensions]. Default [ColorScheme.primary] is
/// guardian plum for pet-guardian-first landing; use [primaryFor] in routed UI.
@immutable
class ExperienceColors extends ThemeExtension<ExperienceColors> {
  const ExperienceColors({
    required this.guardianPrimary,
    required this.guardianOnPrimary,
    required this.guardianHover,
    required this.guardianActive,
    required this.guardianLight,
    required this.guardianSoft,
    required this.organizationPrimary,
    required this.organizationOnPrimary,
    required this.organizationHover,
    required this.organizationActive,
    required this.organizationLight,
    required this.organizationSoft,
    required this.warmAccent,
    required this.warmAccentLight,
    required this.success,
    required this.successLight,
    required this.warning,
    required this.danger,
    required this.info,
  });

  final Color guardianPrimary;
  final Color guardianOnPrimary;
  final Color guardianHover;
  final Color guardianActive;
  final Color guardianLight;
  final Color guardianSoft;

  final Color organizationPrimary;
  final Color organizationOnPrimary;
  final Color organizationHover;
  final Color organizationActive;
  final Color organizationLight;
  final Color organizationSoft;

  final Color warmAccent;
  final Color warmAccentLight;

  final Color success;
  final Color successLight;
  final Color warning;
  final Color danger;
  final Color info;

  static const ExperienceColors light = ExperienceColors(
    guardianPrimary: AppColorTokens.guardianPrimary,
    guardianOnPrimary: AppColorTokens.inverse,
    guardianHover: AppColorTokens.guardianHover,
    guardianActive: AppColorTokens.guardianActive,
    guardianLight: AppColorTokens.guardianLight,
    guardianSoft: AppColorTokens.guardianSoft,
    organizationPrimary: AppColorTokens.organizationPrimary,
    organizationOnPrimary: AppColorTokens.inverse,
    organizationHover: AppColorTokens.organizationHover,
    organizationActive: AppColorTokens.organizationActive,
    organizationLight: AppColorTokens.organizationLight,
    organizationSoft: AppColorTokens.organizationSoft,
    warmAccent: AppColorTokens.warmAccent,
    warmAccentLight: AppColorTokens.warmAccentLight,
    success: AppColorTokens.success,
    successLight: AppColorTokens.successLight,
    warning: AppColorTokens.warning,
    danger: AppColorTokens.danger,
    info: AppColorTokens.info,
  );

  Color primaryFor({required bool organization}) =>
      organization ? organizationPrimary : guardianPrimary;

  Color onPrimaryFor({required bool organization}) =>
      organization ? organizationOnPrimary : guardianOnPrimary;

  @override
  ExperienceColors copyWith({
    Color? guardianPrimary,
    Color? guardianOnPrimary,
    Color? guardianHover,
    Color? guardianActive,
    Color? guardianLight,
    Color? guardianSoft,
    Color? organizationPrimary,
    Color? organizationOnPrimary,
    Color? organizationHover,
    Color? organizationActive,
    Color? organizationLight,
    Color? organizationSoft,
    Color? warmAccent,
    Color? warmAccentLight,
    Color? success,
    Color? successLight,
    Color? warning,
    Color? danger,
    Color? info,
  }) {
    return ExperienceColors(
      guardianPrimary: guardianPrimary ?? this.guardianPrimary,
      guardianOnPrimary: guardianOnPrimary ?? this.guardianOnPrimary,
      guardianHover: guardianHover ?? this.guardianHover,
      guardianActive: guardianActive ?? this.guardianActive,
      guardianLight: guardianLight ?? this.guardianLight,
      guardianSoft: guardianSoft ?? this.guardianSoft,
      organizationPrimary: organizationPrimary ?? this.organizationPrimary,
      organizationOnPrimary:
          organizationOnPrimary ?? this.organizationOnPrimary,
      organizationHover: organizationHover ?? this.organizationHover,
      organizationActive: organizationActive ?? this.organizationActive,
      organizationLight: organizationLight ?? this.organizationLight,
      organizationSoft: organizationSoft ?? this.organizationSoft,
      warmAccent: warmAccent ?? this.warmAccent,
      warmAccentLight: warmAccentLight ?? this.warmAccentLight,
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
    );
  }

  @override
  ExperienceColors lerp(ThemeExtension<ExperienceColors>? other, double t) {
    if (other is! ExperienceColors) return this;
    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t)!;
    return ExperienceColors(
      guardianPrimary: lerpColor(guardianPrimary, other.guardianPrimary),
      guardianOnPrimary: lerpColor(guardianOnPrimary, other.guardianOnPrimary),
      guardianHover: lerpColor(guardianHover, other.guardianHover),
      guardianActive: lerpColor(guardianActive, other.guardianActive),
      guardianLight: lerpColor(guardianLight, other.guardianLight),
      guardianSoft: lerpColor(guardianSoft, other.guardianSoft),
      organizationPrimary: lerpColor(
        organizationPrimary,
        other.organizationPrimary,
      ),
      organizationOnPrimary: lerpColor(
        organizationOnPrimary,
        other.organizationOnPrimary,
      ),
      organizationHover: lerpColor(organizationHover, other.organizationHover),
      organizationActive: lerpColor(
        organizationActive,
        other.organizationActive,
      ),
      organizationLight: lerpColor(organizationLight, other.organizationLight),
      organizationSoft: lerpColor(organizationSoft, other.organizationSoft),
      warmAccent: lerpColor(warmAccent, other.warmAccent),
      warmAccentLight: lerpColor(warmAccentLight, other.warmAccentLight),
      success: lerpColor(success, other.success),
      successLight: lerpColor(successLight, other.successLight),
      warning: lerpColor(warning, other.warning),
      danger: lerpColor(danger, other.danger),
      info: lerpColor(info, other.info),
    );
  }
}

extension ExperienceColorsContext on BuildContext {
  ExperienceColors get experienceColors =>
      Theme.of(this).extension<ExperienceColors>() ?? ExperienceColors.light;
}
