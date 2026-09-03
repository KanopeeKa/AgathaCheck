import 'package:flutter/material.dart';

/// Target dimensions for [UnifiedPetTile] across carousel and grid layouts.
class PetTileDimensions {
  const PetTileDimensions._({required this.width, required this.height});

  final double width;
  final double height;

  static const double minWidth = 120;
  static const double maxWidth = 172;
  static const double baseHeight = 140;

  /// Responsive tile width for a carousel or grid at [viewportWidth].
  static double widthFor(double viewportWidth) {
    if (viewportWidth < 600) return 128;
    if (viewportWidth < 900) return 148;
    if (viewportWidth < 1200) return 160;
    return maxWidth;
  }

  /// Tile height grows with text scale for accessibility.
  static double heightFor(BuildContext context) {
    final scaled14 = MediaQuery.textScalerOf(context).scale(14);
    final ratio = scaled14 / 14;
    final extra = ((scaled14 - 14).clamp(0.0, 20.0)) * 3.5;
    final largeTextBump = ratio >= 1.75 ? 16.0 : 0.0;
    return baseHeight + extra + largeTextBump;
  }

  /// Photo vs text flex weights — give text more room when scaled up.
  static ({int photo, int text}) flexFor(BuildContext context) {
    final ratio = MediaQuery.textScalerOf(context).scale(14) / 14;
    if (ratio >= 1.75) return (photo: 3, text: 2);
    if (ratio >= 1.3) return (photo: 5, text: 3);
    return (photo: 3, text: 2);
  }

  static PetTileDimensions resolve(BuildContext context, double viewportWidth) {
    return PetTileDimensions._(
      width: widthFor(viewportWidth),
      height: heightFor(context),
    );
  }
}
