import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/shell_return_navigation.dart';
import '../../../../core/weight/weight_unit_preference.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../experience/domain/entities/app_experience.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../domain/weight_entry_sort.dart';
import '../providers/weight_providers.dart';
import '../sheets/record_weight_sheet.dart';
import '../widgets/weight_chart.dart';
import '../widgets/weight_hub_empty_state.dart';
import '../widgets/weight_hub_history_list.dart';
import '../widgets/weight_hub_routines_card.dart';
import '../widgets/weight_hub_summary_card.dart';

/// Weight hub for a pet (summary, chart, routines, history).
class WeightHubScreen extends ConsumerWidget {
  const WeightHubScreen({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(weightEntriesNotifierProvider(petId));
    final overviewAsync = ref.watch(weightOverviewProvider(petId));

    void onRecord() => showRecordWeightSheet(context, ref, petId: petId);

    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.weightTracking,
      backPath: petDetailBackPath(context, petId),
      contextualActions: [
        IconButton(
          key: const Key('weight_tracking_add_app_bar'),
          tooltip: l.weightRecordAction,
          icon: const Icon(Icons.add),
          onPressed: onRecord,
        ),
      ],
      child: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l.errorLoadingWeightData(error.toString())),
        ),
        data: (entries) {
          final sorted = sortWeightEntriesNewestFirst(entries);
          final overview = overviewAsync.valueOrNull;
          final unit = ref.watch(weightUnitPreferenceProvider);
          final targetKg = overview?.reference?.valueKg;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (sorted.isEmpty)
                  const WeightHubEmptyState()
                else ...[
                  WeightHubSummaryCard(entries: sorted, overview: overview),
                  if (sorted.length >= 2)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: WeightChart(
                        entries: sorted,
                        unit: unit,
                        targetKg: targetKg,
                      ),
                    ),
                  WeightHubHistoryList(petId: petId, entries: sorted),
                ],
                WeightHubRoutinesCard(petId: petId, overview: overview),
                WeightHubAddFooterButton(
                  onPressed: onRecord,
                  label: l.weightRecordAction,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
