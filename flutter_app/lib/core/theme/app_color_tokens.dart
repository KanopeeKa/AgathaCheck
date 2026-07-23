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
}
