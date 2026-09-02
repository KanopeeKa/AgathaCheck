import 'package:flutter/material.dart';

import 'app_color_tokens.dart';

/// Experience-aware colors (pet care plum vs organisation teal).
///
/// Registered on [ThemeData.extensions]. Default [ColorScheme.primary] is
/// pet care plum for pet-care-first landing; use [primaryFor] in routed UI.
@immutable
class ExperienceColors extends ThemeExtension<ExperienceColors> {
  const ExperienceColors({
    required this.petCarePrimary,
    required this.petCareOnPrimary,
    required this.petCareHover,
    required this.petCareActive,
    required this.petCareLight,
    required this.petCareSoft,
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

  final Color petCarePrimary;
  final Color petCareOnPrimary;
  final Color petCareHover;
  final Color petCareActive;
  final Color petCareLight;
  final Color petCareSoft;

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

  @Deprecated('Use petCarePrimary')
  Color get guardianPrimary => petCarePrimary;
  @Deprecated('Use petCareOnPrimary')
  Color get guardianOnPrimary => petCareOnPrimary;
  @Deprecated('Use petCareHover')
  Color get guardianHover => petCareHover;
  @Deprecated('Use petCareActive')
  Color get guardianActive => petCareActive;
  @Deprecated('Use petCareLight')
  Color get guardianLight => petCareLight;
  @Deprecated('Use petCareSoft')
  Color get guardianSoft => petCareSoft;

  static const ExperienceColors light = ExperienceColors(
    petCarePrimary: AppColorTokens.petCarePrimary,
    petCareOnPrimary: AppColorTokens.inverse,
    petCareHover: AppColorTokens.petCareHover,
    petCareActive: AppColorTokens.petCareActive,
    petCareLight: AppColorTokens.petCareLight,
    petCareSoft: AppColorTokens.petCareSoft,
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
      organization ? organizationPrimary : petCarePrimary;

  Color onPrimaryFor({required bool organization}) =>
      organization ? organizationOnPrimary : petCareOnPrimary;

  @override
  ExperienceColors copyWith({
    Color? petCarePrimary,
    Color? petCareOnPrimary,
    Color? petCareHover,
    Color? petCareActive,
    Color? petCareLight,
    Color? petCareSoft,
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
      petCarePrimary: petCarePrimary ?? this.petCarePrimary,
      petCareOnPrimary: petCareOnPrimary ?? this.petCareOnPrimary,
      petCareHover: petCareHover ?? this.petCareHover,
      petCareActive: petCareActive ?? this.petCareActive,
      petCareLight: petCareLight ?? this.petCareLight,
      petCareSoft: petCareSoft ?? this.petCareSoft,
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
      petCarePrimary: lerpColor(petCarePrimary, other.petCarePrimary),
      petCareOnPrimary: lerpColor(petCareOnPrimary, other.petCareOnPrimary),
      petCareHover: lerpColor(petCareHover, other.petCareHover),
      petCareActive: lerpColor(petCareActive, other.petCareActive),
      petCareLight: lerpColor(petCareLight, other.petCareLight),
      petCareSoft: lerpColor(petCareSoft, other.petCareSoft),
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
