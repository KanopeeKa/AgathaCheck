import 'package:flutter/material.dart';

import '../../../../../core/widgets/branded_logo.dart';
import 'package:pet_profile_app/core/experience/app_experience.dart';

Widget buildLandingLogo(ThemeData theme, {required double size}) {
  return BrandedLogo(
    size: size,
    experience: AppExperience.petCare,
    useJpg: true,
    clipOval: true,
  );
}
