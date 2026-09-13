import 'package:flutter/material.dart';

import '../../../../../core/theme/app_color_tokens.dart';

/// Shared spacing and emphasis constants for care surface primitives.
abstract final class CareSurfaceTokens {
  static const double attentionRadius = 12;
  static const double actionRadius = 12;
  static const double insightRadius = 12;
  static const double rowMinHeight = 48;

  static const EdgeInsets attentionPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );
  static const EdgeInsets actionPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );
  static const EdgeInsets insightPadding = EdgeInsets.all(12);
  static const EdgeInsets destinationPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );

  static Color attentionBackground(ColorScheme colorScheme) =>
      AppColorTokens.dangerLight;
  static Color attentionForeground(ColorScheme colorScheme) =>
      AppColorTokens.body;
  static Color attentionIcon(ColorScheme colorScheme) => AppColorTokens.danger;

  static Color insightBackground(ColorScheme colorScheme) =>
      colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);
  static Color insightBorder(ColorScheme colorScheme) =>
      colorScheme.outlineVariant;
}
