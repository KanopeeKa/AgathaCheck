import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/experience_colors.dart';
import '../../../experience/domain/entities/app_experience.dart';
import '../../../experience/presentation/utils/experience_theme.dart';

/// Organisation teal primary for standalone org routes outside the shell.
ThemeData orgExperienceTheme(BuildContext context) =>
    themeForAppExperience(Theme.of(context), AppExperience.organization);

Widget orgThemed({required Widget child}) {
  return Builder(
    builder: (context) =>
        Theme(data: orgExperienceTheme(context), child: child),
  );
}

/// Navigation v2 org list palette — see [docs/design/navigation-v2.md].
Color orgListScaffoldBackground(BuildContext context) =>
    context.experienceColors.organizationLight;

Color orgListCardColor() => AppColorTokens.surface;

CardThemeData orgListCardTheme() {
  return const CardThemeData(
    color: AppColorTokens.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );
}
