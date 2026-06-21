import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../weight_tracking/domain/entities/weight_entry.dart';
import '../../../../weight_tracking/presentation/providers/weight_providers.dart';

/// A line chart visualising a pet's weight history over time.
///
/// Expects at least two [entries]; the caller is responsible for that check.
/// Weights are converted from the stored kilograms into [unit] for display.
class WeightChart extends StatelessWidget {
  const WeightChart({
    required this.entries,
    required this.unit,
    super.key,
  });

  /// The weight entries to plot. Order is irrelevant — the chart sorts a copy
  /// chronologically before rendering.
  final List<WeightEntry> entries;

  /// The unit the y-axis values are displayed in.
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unitLabel = weightUnitLabel(unit);

    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final spots = <FlSpot>[
      for (var i = 0; i < sorted.length; i++)
        FlSpot(i.toDouble(), convertWeight(sorted[i].weight, unit)),
    ];

    final values = spots.map((s) => s.y).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    // Pad the range so the line never touches the chart edges, and keep a
    // sensible range even when every entry has the same weight.
    final padding = ((maxValue - minValue) * 0.15).clamp(0.5, double.infinity);
    final minY = minValue - padding;
    final maxY = maxValue + padding;
    final yInterval = ((maxY - minY) / 3).clamp(0.1, double.infinity);

    final lastIndex = sorted.length - 1;
    final midIndex = lastIndex ~/ 2;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: lastIndex.toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value < minY || value > maxY) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    value.toStringAsFixed(1),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index != 0 && index != lastIndex && index != midIndex) {
                  return const SizedBox.shrink();
                }
                if (index < 0 || index > lastIndex) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat.Md().format(sorted[index].date),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => colorScheme.inverseSurface,
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final date = sorted[spot.x.round()].date;
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)} $unitLabel\n'
                '${DateFormat.yMMMd().format(date)}',
                theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onInverseSurface,
                      fontWeight: FontWeight.w600,
                    ) ??
                    const TextStyle(),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.2,
            color: colorScheme.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: colorScheme.primary,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
