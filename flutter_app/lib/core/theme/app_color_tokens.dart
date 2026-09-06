import 'package:flutter/material.dart';

/// Canonical color constants for AgathaTrack.
///
/// See [docs/design/tokens.md]. Prefer [Theme.of] / [ExperienceColors] in UI code.
abstract final class AppColorTokens {
  // Foundations
  static const Color background = Color(0xFFEAE8E8);
  static const Color surface = Color(0xFFFFFDFC);
  static const Color surfaceAlt = Color(0xFFF2ECE6);
  static const Color border = Color(0xFFE4DDD6);
  static const Color borderStrong = Color(0xFFD6CBC3);

  // Typography
  static const Color heading = Color(0xFF1F2937);
  static const Color body = Color(0xFF374151);
  static const Color muted = Color(0xFF667085);
  static const Color disabled = Color(0xFF98A2B3);
  static const Color inverse = Color(0xFFFFFFFF);
  static const Color shadow = Color(0x141F2937);

  // Pet Care (formerly Guardian plum)
  static const Color petCarePrimary = Color(0xFF755B68);
  static const Color petCareHover = Color(0xFF664C59);
  static const Color petCareActive = Color(0xFF573F4B);
  static const Color petCareLight = Color(0xFFE8E1E3);
  static const Color petCareSoft = Color(0xFFE7DCE2);

  @Deprecated('Use petCareHover')
  static const Color guardianHover = petCareHover;
  @Deprecated('Use petCareActive')
  static const Color guardianActive = petCareActive;
  @Deprecated('Use petCareLight')
  static const Color guardianLight = petCareLight;
  @Deprecated('Use petCareSoft')
  static const Color guardianSoft = petCareSoft;

  // Pet care workspace aliases for home widgets migrating from guardianCare*.
  static const Color petCareCarePrimary = petCarePrimary;
  static const Color petCareCareActive = petCareActive;
  static const Color petCareCareLight = petCareLight;

  @Deprecated('Use petCareCarePrimary')
  static const Color guardianCarePrimary = petCareCarePrimary;
  @Deprecated('Use petCareCareActive')
  static const Color guardianCareActive = petCareCareActive;
  @Deprecated('Use petCareCareLight')
  static const Color guardianCareLight = petCareCareLight;

  // Public landing: warm paper, Pet Care plum, and Shelter teal.
  static const Color landingCanvas = background;
  static const Color landingSurface = Color(0xFFFFFDFC);
  static const Color landingInk = heading;
  static const Color landingInkSoft = Color(0xFF52606D);
  static const Color landingTeal = Color(0xFF1D7C84);
  static const Color landingTealDeep = Color(0xFF14656C);
  static const Color landingTealSoft = Color(0xFFE6F2F2);
  static const Color landingLine = Color(0xFFD9E5E1);
  static const Color landingInput = Color(0xFFFFFDFC);
  static const Color landingFocus = landingTeal;

  // Transitional aliases for pre-refresh public and consent UI. New code must
  // use the semantic landing tokens above, not these legacy Operations names.
  static const Color operationsOlive = landingTealDeep;
  static const Color operationsOliveLight = landingTeal;
  static const Color operationsPaper = landingCanvas;
  static const Color operationsSurface = landingSurface;
  static const Color operationsInk = landingInk;
  static const Color operationsGold = petCarePrimary;
  static const Color operationsDeskCanvas = landingCanvas;

  // Organisation context — distinct from warning and error semantics.
  static const Color organizationOchre = Color(0xFFB98223);
  static const Color organizationOchreLight = Color(0xFFF8EDCE);

  // Organisation
  static const Color organizationPrimary = landingTeal;
  static const Color organizationHover = Color(0xFF176972);
  static const Color organizationActive = Color(0xFF125860);
  static const Color organizationLight = Color(0xFFEAF5F5);
  static const Color organizationSoft = Color(0xFFD8ECEC);

  // Warm accent (not primary CTA)
  static const Color warmAccent = Color(0xFFD6A08F);
  static const Color warmAccentLight = Color(0xFFF4E4DD);
  static const Color warmAccentText = Color(0xFF8B5E4A);

  // Semantic
  static const Color info = Color(0xFF5C7EA6);
  static const Color success = Color(0xFF2B7A2E);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFD6A63A);
  static const Color danger = Color(0xFFC65B58);

  /// Memorial overlay on passed-away pet photos (lighten blend).
  static const Color passedAwayPhotoOverlay = Color(0xDDFFFFFF);

  /// Org member role border accents (avatar/card ring).
  static const Color orgSuperAdminBorder = Color(0xFFD4AF37);
  static const Color orgAdminBorder = Color(0xFFC0C0C0);

  /// Rainbow gradient for passed-away memorial icon (pet form).
  static const List<Color> petRainbowIconGradient = [
    Color(0xFFFF0000),
    Color(0xFFFF8800),
    Color(0xFFFFFF00),
    Color(0xFF00CC00),
    Color(0xFF0066FF),
    Color(0xFF8800CC),
  ];
}
