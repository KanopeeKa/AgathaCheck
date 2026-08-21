import 'package:flutter/material.dart';

/// Canonical color constants for AgathaTrack.
///
/// See [docs/design/tokens.md]. Prefer [Theme.of] / [ExperienceColors] in UI code.
abstract final class AppColorTokens {
  // Foundations
  static const Color background = Color(0xFFF8F5F1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF3EDE7);
  static const Color border = Color(0xFFE5DDD6);
  static const Color borderStrong = Color(0xFFD5CCC4);

  // Typography
  static const Color heading = Color(0xFF2D3338);
  static const Color body = Color(0xFF394249);
  static const Color muted = Color(0xFF68737A);
  static const Color disabled = Color(0xFFA3ABB1);
  static const Color inverse = Color(0xFFFFFFFF);

  // Guardian
  static const Color guardianPrimary = Color(0xFF755B68);
  static const Color guardianHover = Color(0xFF664C59);
  static const Color guardianActive = Color(0xFF573F4B);
  static const Color guardianLight = Color(0xFFF4EEF2);
  static const Color guardianSoft = Color(0xFFE7DCE2);

  // Guardian operations desk (guardian care) — reserved for the guardian home
  // presentation while the wider experience colour migration is phased.
  static const Color guardianCarePrimary = Color(0xFF5E7A68);
  static const Color guardianCareActive = Color(0xFF405B4B);
  static const Color guardianCareLight = Color(0xFFE8F1E9);

  // Guardian Operations Desk surfaces. These are intentionally scoped to the
  // landing and guardian desk rather than replacing the global app palette.
  static const Color operationsOlive = Color(0xFF2F4439);
  static const Color operationsOliveLight = Color(0xFF3F6250);
  static const Color operationsPaper = Color(0xFFF5F2E9);
  static const Color operationsSurface = Color(0xFFFFFDF8);
  static const Color operationsInk = Color(0xFF26332C);
  static const Color operationsGold = Color(0xFFC9A65A);
  static const Color operationsDeskCanvas = Color(0xFFF0EEE5);

  // Organisation context — distinct from warning and error semantics.
  static const Color organizationOchre = Color(0xFFB98223);
  static const Color organizationOchreLight = Color(0xFFF8EDCE);

  // Organisation
  static const Color organizationPrimary = Color(0xFF218B6C);
  static const Color organizationHover = Color(0xFF1B765C);
  static const Color organizationActive = Color(0xFF17664F);
  static const Color organizationLight = Color(0xFFEAF7F2);
  static const Color organizationSoft = Color(0xFFD8EFE6);

  // Warm accent (not primary CTA)
  static const Color warmAccent = Color(0xFFD6A08F);
  static const Color warmAccentLight = Color(0xFFF4E4DD);

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
