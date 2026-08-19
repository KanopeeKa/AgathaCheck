import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/experience/domain/entities/app_experience.dart';

/// Experience-compatible paths for the canonical AgathaTrack logo mark.
class LogoAssets {
  LogoAssets._();

  static const plumPng = 'assets/logo-plum.png';
  static const tealPng = 'assets/logo-teal.png';
  static const plumJpg = 'assets/logo-plum.jpg';
  static const tealJpg = 'assets/logo-teal.jpg';

  static String pngFor(AppExperience experience) =>
      experience == AppExperience.organization ? tealPng : plumPng;

  static String jpgFor(AppExperience experience) =>
      experience == AppExperience.organization ? tealJpg : plumJpg;

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
