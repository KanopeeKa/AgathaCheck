import 'package:flutter/material.dart';

import '../../../../core/theme/experience_colors.dart';
import '../../domain/entities/app_experience.dart';

/// Applies guardian plum or organisation teal to [ColorScheme.primary] for routed UI.
ThemeData themeForAppExperience(ThemeData base, AppExperience experience) {
  final isOrg = experience == AppExperience.organization;
  final xp = base.extension<ExperienceColors>() ?? ExperienceColors.light;

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: xp.primaryFor(organization: isOrg),
      onPrimary: xp.onPrimaryFor(organization: isOrg),
      primaryContainer: isOrg ? xp.organizationLight : xp.guardianLight,
      onPrimaryContainer: isOrg ? xp.organizationPrimary : xp.guardianActive,
    ),
  );
}
