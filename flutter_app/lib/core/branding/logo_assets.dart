import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/experience/domain/entities/app_experience.dart';

/// Experience-compatible paths for the canonical AgathaTrack logo mark.
class LogoAssets {
  LogoAssets._();

  static const plumPng = 'assets/logo-plum.png';
  static const plumDarkPng = 'assets/logo-plum-dark.png';
  static const guardianLightTealPng = 'assets/logo-guardian-light-teal.png';
  static const tealPng = 'assets/logo-teal.png';
  static const plumJpg = 'assets/logo-plum.jpg';
  static const tealJpg = 'assets/logo-teal.jpg';

  static const careMarkLightPng =
      'assets/branding/agathatrack-care-mark-light.png';
  static const careMarkDarkPng =
      'assets/branding/agathatrack-care-mark-dark.png';

  /// Standard mark for light surfaces; light monochrome marks on dark surfaces.
  static String pngFor(
    AppExperience experience, {
    bool onDarkBackground = false,
  }) {
    if (onDarkBackground) {
      return experience == AppExperience.organization
          ? guardianLightTealPng
          : plumDarkPng;
    }
    return experience == AppExperience.organization ? tealPng : plumPng;
  }

  /// Guardian compact chrome uses the plum app bar (dark); org shell stays light.
  static String pngForShell(AppExperience experience) => pngFor(
    experience,
    onDarkBackground: experience == AppExperience.guardian,
  );

  static String jpgFor(AppExperience experience) =>
      experience == AppExperience.organization ? tealJpg : plumJpg;

  static String careMarkPng({bool onDarkBackground = false}) =>
      onDarkBackground ? careMarkDarkPng : careMarkLightPng;

  /// Org routes use teal; everything else defaults to guardian plum.
  static AppExperience experienceForRoute(String location) {
    if (location.startsWith('/organizations')) {
      return AppExperience.organization;
    }
    if (location == '/o' || location.startsWith('/o/')) {
      return AppExperience.organization;
    }
    return AppExperience.guardian;
  }

  static AppExperience experienceForContext(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return AppExperience.guardian;
    final path = router.routerDelegate.currentConfiguration.uri.path;
    return experienceForRoute(path);
  }
}
