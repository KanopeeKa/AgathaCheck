import 'package:flutter/material.dart';

/// Target dimensions for [UnifiedPetTile] across carousel and grid layouts.
class PetTileDimensions {
  const PetTileDimensions._({
    required this.width,
    required this.height,
  });

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
    final scale = MediaQuery.textScalerOf(context).scale(14);
    if (scale > 20) return baseHeight + 32;
    if (scale > 18) return baseHeight + 24;
    if (scale > 15) return baseHeight + 12;
    return baseHeight;
  }

  static PetTileDimensions resolve(BuildContext context, double viewportWidth) {
    return PetTileDimensions._(
      width: widthFor(viewportWidth),
      height: heightFor(context),
    );
  }
}
