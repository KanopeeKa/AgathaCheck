import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';

/// Compact weight sparkline for the care-item observation block (no pet_care import).
class WeightTrendSparkline extends StatelessWidget {
  const WeightTrendSparkline({
    super.key,
    required this.values,
    this.semanticLabel,
    this.emptyLabel = 'No trend yet',
    this.insufficientLabel = 'Not enough data',
    this.minPoints = 2,
    this.height = 40,
  });

  final List<double> values;
  final String? semanticLabel;
  final String emptyLabel;
  final String insufficientLabel;
  final int minPoints;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stroke = AppColorTokens.petCarePrimary;

    if (values.isEmpty) {
      return _StatePanel(
        label: emptyLabel,
        semanticLabel: semanticLabel ?? emptyLabel,
        colorScheme: colorScheme,
        height: height,
      );
    }

    if (values.length < minPoints) {
      return _StatePanel(
        label: insufficientLabel,
        semanticLabel: semanticLabel ?? insufficientLabel,
        colorScheme: colorScheme,
        height: height,
      );
    }

    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: SizedBox(
        key: const Key('weight_care_item_sparkline'),
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _SparklinePainter(values: values, color: stroke),
        ),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.label,
    required this.semanticLabel,
    required this.colorScheme,
    required this.height,
  });

  final String label;
  final String semanticLabel;
  final ColorScheme colorScheme;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Container(
        height: height,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs() < 0.0001
        ? 1.0
        : maxValue - minValue;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final normalized = (values[index] - minValue) / range;
      final y = size.height - (normalized * (size.height - 4)) - 2;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
