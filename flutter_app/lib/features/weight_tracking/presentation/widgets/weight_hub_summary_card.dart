import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../core/weight/weight_unit.dart';
import '../../../../core/weight/weight_unit_preference.dart';
import '../../../../core/widgets/async_state/async_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/weight_entry.dart';
import '../../domain/entities/weight_overview.dart';
import '../providers/weight_providers.dart';
import '../utils/weight_hub_labels.dart';

class WeightHubSummaryCard extends ConsumerWidget {
  const WeightHubSummaryCard({
    required this.petId,
    required this.entries,
    required this.overviewAsync,
    super.key,
  });

  final String petId;
  final List<WeightEntry> entries;
  final AsyncValue<WeightOverview> overviewAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitPreferenceProvider);
    final setUnit = ref.read(setWeightUnitPreferenceProvider);

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final latest = entries.first;
    final previous = entries.length > 1 ? entries[1] : null;
    final display = formatWeight(latest.weight, unit);
    final recorded = l.weightRecordedOn(
      DateFormat.yMMMd().format(calendarDateOnly(latest.date)),
    );

    String? changeLine;
    if (previous != null) {
      final delta = latest.weight - previous.weight;
      if (delta.abs() >= 0.05) {
        changeLine = formatWeightChange(l, delta, unit, previous.date);
      }
    }

    final overview = overviewAsync.valueOrNull;
    String? targetLine;
    final refData = overview?.reference;
    if (refData != null) {
      final targetDisplay = formatWeight(refData.valueKg, unit);
      targetLine = l.weightTargetLine(
        targetDisplay,
        weightAuthorityLabel(l, refData.authority),
      );
    }

    final overviewCaption = overviewAsync.whenOrNull(
      loading: () => SupplementalStateCaption(
        state: SupplementalState.loading,
        label: l.weightTargetRoutineLoading,
      ),
      error: (_, __) => SupplementalStateCaption(
        state: SupplementalState.unavailable,
        label: l.weightTargetRoutineUnavailable,
        onRetry: () => ref.invalidate(weightOverviewProvider(petId)),
        retryKey: const Key('weight_hub_overview_retry'),
      ),
    );

    return Card(
      key: const Key('weight_hub_summary'),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        display,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        recorded,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (changeLine != null) ...[
                        const SizedBox(height: 4),
                        Text(changeLine, style: theme.textTheme.bodySmall),
                      ],
                      if (targetLine != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          targetLine,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (overviewCaption != null) ...[
                        const SizedBox(height: 8),
                        overviewCaption,
                      ],
                    ],
                  ),
                ),
                SegmentedButton<WeightUnit>(
                  segments: const [
                    ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
                    ButtonSegment(value: WeightUnit.lb, label: Text('lb')),
                  ],
                  selected: {unit},
                  onSelectionChanged: (sel) => setUnit(sel.first),
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
