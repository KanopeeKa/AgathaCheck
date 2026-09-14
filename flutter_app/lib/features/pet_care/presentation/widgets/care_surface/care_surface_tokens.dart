import 'package:flutter/material.dart';

import '../../../../../core/theme/app_color_tokens.dart';

/// Shared spacing and emphasis constants for care surface primitives.
abstract final class CareSurfaceTokens {
  static const double attentionRadius = 12;
  static const double actionRadius = 12;
  static const double insightRadius = 16;
  static const double collectionRadius = 16;
  static const double rowMinHeight = 48;

  static const EdgeInsets attentionPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );
  static const EdgeInsets actionPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );
  static const EdgeInsets insightPadding = EdgeInsets.all(16);
  static const EdgeInsets destinationPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );
  static const EdgeInsets collectionHeaderPadding = EdgeInsets.fromLTRB(
    16,
    12,
    16,
    4,
  );

  /// Horizontal inset for rows inside a collection (matches legacy desk card padding).
  static const EdgeInsets collectionRowPadding = EdgeInsets.symmetric(
    horizontal: 16,
  );

  static const EdgeInsets collectionInsetRowPadding = EdgeInsets.fromLTRB(
    16,
    8,
    16,
    8,
  );

  static Color attentionBackground(ColorScheme colorScheme) =>
      AppColorTokens.dangerLight;
  static Color attentionForeground(ColorScheme colorScheme) =>
      AppColorTokens.body;
  static Color attentionIcon(ColorScheme colorScheme) => AppColorTokens.danger;

  static Color collectionBackground() => AppColorTokens.petCareCollection;
  static Color collectionDivider() => AppColorTokens.petCareCollectionDivider;

  static Color moduleBackground() => AppColorTokens.surface;
  static Color moduleBorder() => AppColorTokens.border;
}
