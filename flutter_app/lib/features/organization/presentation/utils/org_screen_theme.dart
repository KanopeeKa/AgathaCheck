import 'package:flutter/material.dart';

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
