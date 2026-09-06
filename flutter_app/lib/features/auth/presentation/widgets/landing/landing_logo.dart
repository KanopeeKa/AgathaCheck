import 'package:flutter/material.dart';

import '../../../../../core/widgets/branded_logo.dart';
import '../../../../../features/experience/domain/entities/app_experience.dart';

Widget buildLandingLogo(ThemeData theme, {required double size}) {
  return BrandedLogo(
    size: size,
    experience: AppExperience.petCare,
    useJpg: true,
    clipOval: true,
  );
}
