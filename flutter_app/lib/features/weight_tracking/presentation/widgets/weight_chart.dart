import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/weight_entry.dart';
import '../../domain/weight_entry_sort.dart';
import '../providers/weight_providers.dart';

/// Line chart for weight history; markers differ when a point [WeightEntry.fulfils].
class WeightChart extends StatelessWidget {
  const WeightChart({
    required this.entries,
    required this.unit,
    this.targetKg,
    super.key,
  });

  final List<WeightEntry> entries;
  final WeightUnit unit;
  final double? targetKg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final unitLabel = weightUnitLabel(unit);

    final sorted = sortWeightEntriesChronological(entries);
    final spots = <FlSpot>[
      for (var i = 0; i < sorted.length; i++)
        FlSpot(i.toDouble(), convertWeight(sorted[i].weight, unit)),
    ];

    final values = spots.map((s) => s.y).toList();
    if (targetKg != null) {
      values.add(convertWeight(targetKg!, unit));
    }
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final padding = ((maxValue - minValue) * 0.15).clamp(0.5, double.infinity);
    final minY = minValue - padding;
    final maxY = maxValue + padding;
    final yInterval = ((maxY - minY) / 3).clamp(0.1, double.infinity);

    final lastIndex = sorted.length - 1;
    final midIndex = lastIndex ~/ 2;

    final targetY = targetKg != null ? convertWeight(targetKg!, unit) : null;

    return Semantics(
      label: l.weightChartLabel(sorted.length),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: lastIndex.toDouble(),
                minY: minY,
                maxY: maxY,
                extraLinesData: targetY == null
                    ? null
                    : ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: targetY,
                            color: colorScheme.outline,
                            strokeWidth: 1.5,
                            dashArray: [6, 4],
                          ),
                        ],
                      ),
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
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
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
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
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
                        if (index != 0 &&
                            index != lastIndex &&
                            index != midIndex) {
                          return const SizedBox.shrink();
                        }
                        if (index < 0 || index > lastIndex) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat.Md().format(
                              calendarDateOnly(sorted[index].date),
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
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
                      final date = calendarDateOnly(
                        sorted[spot.x.round()].date,
                      );
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
                      getDotPainter: (spot, percent, bar, index) {
                        final weighsIn = sorted[index].fulfils != null;
                        if (weighsIn) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: colorScheme.primary,
                            strokeWidth: 0,
                          );
                        }
                        return FlDotCirclePainter(
                          radius: 4,
                          color: colorScheme.surface,
                          strokeWidth: 2,
                          strokeColor: colorScheme.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colorScheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '● ${l.weightLegendWeighIn}',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(width: 16),
              Text(
                '○ ${l.weightLegendOther}',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
