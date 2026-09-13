import 'package:flutter/material.dart';

import 'care_surface_tokens.dart';
import 'care_trend_sparkline.dart';

/// Insight role — low-emphasis tappable card for derived facts (e.g. weight trend).
class CareInsightTile extends StatelessWidget {
  const CareInsightTile({
    super.key,
    required this.title,
    required this.summary,
    required this.semanticLabel,
    required this.onTap,
    this.sparklineValues = const [],
    this.sparklineSemanticLabel,
    this.emptySparklineLabel = 'No trend yet',
    this.insufficientSparklineLabel = 'Not enough data',
  });

  final String title;
  final String summary;
  final String semanticLabel;
  final VoidCallback onTap;
  final List<double> sparklineValues;
  final String? sparklineSemanticLabel;
  final String emptySparklineLabel;
  final String insufficientSparklineLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: CareSurfaceTokens.insightBackground(colorScheme),
        borderRadius: BorderRadius.circular(CareSurfaceTokens.insightRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CareSurfaceTokens.insightRadius),
          child: Container(
            width: double.infinity,
            padding: CareSurfaceTokens.insightPadding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                CareSurfaceTokens.insightRadius,
              ),
              border: Border.all(
                color: CareSurfaceTokens.insightBorder(colorScheme),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                CareTrendSparkline(
                  values: sparklineValues,
                  semanticLabel: sparklineSemanticLabel,
                  emptyLabel: emptySparklineLabel,
                  insufficientLabel: insufficientSparklineLabel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
