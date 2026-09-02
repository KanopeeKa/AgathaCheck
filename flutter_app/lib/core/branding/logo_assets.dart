import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/experience/domain/entities/app_experience.dart';

/// Experience-compatible paths for the canonical AgathaTrack logo mark.
///
/// Naming convention (authoritative):
/// - `*-dark` care-mark files: **dark-coloured** mark for **light** backgrounds.
/// - `*-light` logo/care-mark files: **light-coloured** mark for **dark** backgrounds.
/// - `logo-plum` / `logo-teal`: dark-coloured monochrome marks for light surfaces.
class LogoAssets {
  LogoAssets._();

  /// Dark plum mark on transparent — light backgrounds.
  static const plumPng = 'assets/logo-plum.png';

  /// Light plum mark on transparent — dark backgrounds (e.g. plum app bar).
  static const plumLightPng = 'assets/logo-plum-light.png';

  /// Dark teal mark on transparent — light backgrounds.
  static const tealPng = 'assets/logo-teal.png';

  /// Light teal mark on transparent — dark backgrounds.
  static const tealLightPng = 'assets/logo-teal-light.png';

  static const plumJpg = 'assets/logo-plum.jpg';
  static const tealJpg = 'assets/logo-teal.jpg';

  /// Dual-colour mark (plum + teal) for light backgrounds.
  static const careMarkOnLightPng =
      'assets/branding/agathatrack-care-mark-dark.png';

  /// Dual-colour mark tuned for dark backgrounds.
  static const careMarkOnDarkPng =
      'assets/branding/agathatrack-care-mark-light.png';

  /// [onDarkBackground] when the logo sits on a dark-coloured surface.
  static String pngFor(
    AppExperience experience, {
    bool onDarkBackground = false,
  }) {
    if (onDarkBackground) {
      return experience == AppExperience.organization
          ? tealLightPng
          : plumLightPng;
    }
    return experience == AppExperience.organization ? tealPng : plumPng;
  }

  /// Guardian compact chrome uses the plum app bar (dark surface).
  static String pngForShell(AppExperience experience) => pngFor(
    experience,
    onDarkBackground: experience == AppExperience.petCare,
  );

  static String jpgFor(AppExperience experience) =>
      experience == AppExperience.organization ? tealJpg : plumJpg;

  /// Care mark for landing and public surfaces.
  static String careMarkPng({bool onDarkBackground = false}) =>
      onDarkBackground ? careMarkOnDarkPng : careMarkOnLightPng;

  /// Org routes use teal; everything else defaults to guardian plum.
  static AppExperience experienceForRoute(String location) {
    if (location.startsWith('/organizations')) {
      return AppExperience.organization;
    }
    if (location == '/o' || location.startsWith('/o/')) {
      return AppExperience.organization;
    }
    if (location == '/pc' || location.startsWith('/pc/')) {
      return AppExperience.petCare;
    }
    if (location == '/pc' || location.startsWith('/pc/')) {
      return AppExperience.petCare;
    }
    return AppExperience.petCare;
  }

  static AppExperience experienceForContext(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return AppExperience.petCare;
    final path = router.routerDelegate.currentConfiguration.uri.path;
    return experienceForRoute(path);
  }
}
