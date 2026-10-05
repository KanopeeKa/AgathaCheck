import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../core/weight/weight_unit_preference.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import '../../../../weight_tracking/domain/weight_entry_sort.dart';
import 'package:pet_profile_app/features/weight_tracking/weight_tracking.dart';
import '../../../data/services/pet_report_profile_section.dart';
import '../../../domain/entities/pet.dart';

/// Compact weight insight tile on the pet profile (spec §9 region 6).
class PetProfileWeightInsightSection extends ConsumerWidget {
  const PetProfileWeightInsightSection({
    super.key,
    required this.petId,
    required this.pet,
  });

  final String petId;
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final unit = ref.watch(weightUnitPreferenceProvider);
    final unitText = unitLabel(unit);
    final entriesAsync = ref.watch(weightEntriesNotifierProvider(petId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: entriesAsync.when(
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, __) => CareInsightTile(
          key: const Key('pet_profile_weight_insight'),
          title: l.weightTracking,
          summary: l.noWeightDataYet,
          semanticLabel: '${l.weightTracking}, ${l.noWeightDataYet}',
          onTap: () => context.push('/pet/$petId/weight'),
        ),
        data: (entries) {
          final sorted = sortWeightEntriesNewestFirst(entries);
          final latestKg = PetProfileSectionBuilder.currentWeightFromEntries(
            sorted,
            pet.weight,
          );
          final sparklineValues = sortWeightEntriesChronological(
            sorted.take(8).toList(),
          ).map((e) => e.weight).toList();

          final summary = latestKg == null
              ? l.noWeightDataYet
              : l.weightInsightLastRecorded(
                  '${toDisplay(latestKg, unit).toStringAsFixed(1)} $unitText',
                  sorted.isNotEmpty
                      ? DateFormat.yMMMd().format(
                          calendarDateOnly(sorted.first.date),
                        )
                      : '—',
                );

          return CareInsightTile(
            key: const Key('pet_profile_weight_insight'),
            title: l.weightTracking,
            summary: summary,
            semanticLabel: '${l.weightTracking}, $summary',
            sparklineValues: sparklineValues,
            sparklineSemanticLabel: l.weightChartLabel(sparklineValues.length),
            emptySparklineLabel: l.noWeightDataYet,
            insufficientSparklineLabel: l.noWeightDataYet,
            onTap: () => context.push('/pet/$petId/weight'),
          );
        },
      ),
    );
  }
}
