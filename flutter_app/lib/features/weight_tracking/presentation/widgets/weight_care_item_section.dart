import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../core/weight/weight_unit.dart';
import '../../../../core/weight/weight_unit_preference.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/weight_entry_sort.dart';
import '../providers/weight_providers.dart';
import 'weight_trend_sparkline.dart';

/// Weight observation body for a weigh-in routine care item (§6.6 W9).
///
/// Module chrome is applied in care item detail (`_CareItemObservationSlot`).
class WeightCareItemSection extends ConsumerWidget {
  const WeightCareItemSection({
    super.key,
    required this.petId,
    required this.entryId,
  });

  final String petId;
  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final unit = ref.watch(weightUnitPreferenceProvider);
    final entriesAsync = ref.watch(weightEntriesNotifierProvider(petId));

    return entriesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => _Body(
        l: l,
        summary: l.noWeightDataYet,
        sparklineValues: const [],
        sparklineSemanticLabel: l.weightChartLabel(0),
        petId: petId,
      ),
      data: (entries) {
        final sorted = sortWeightEntriesNewestFirst(entries);
        final latest = sorted.firstOrNull;
        final sparklineValues = sortWeightEntriesChronological(
          sorted.take(8).toList(),
        ).map((e) => e.weight).toList();

        final summary = latest == null
            ? l.noWeightDataYet
            : '${formatWeight(latest.weight, unit)} · ${l.weightRecordedOn(DateFormat.yMMMd().format(calendarDateOnly(latest.date)))}';

        return _Body(
          l: l,
          summary: summary,
          sparklineValues: sparklineValues,
          sparklineSemanticLabel: l.weightChartLabel(sparklineValues.length),
          petId: petId,
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.l,
    required this.summary,
    required this.sparklineValues,
    required this.sparklineSemanticLabel,
    required this.petId,
  });

  final AppLocalizations l;
  final String summary;
  final List<double> sparklineValues;
  final String sparklineSemanticLabel;
  final String petId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      key: const Key('weight_care_item_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          summary,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        WeightTrendSparkline(
          values: sparklineValues,
          semanticLabel: sparklineSemanticLabel,
          emptyLabel: l.noWeightDataYet,
          insufficientLabel: l.noWeightDataYet,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('weight_care_item_see_all'),
            onPressed: () => context.push('/pet/$petId/weight'),
            child: Text(l.weightSeeAll),
          ),
        ),
      ],
    );
  }
}
