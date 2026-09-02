import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pet_profile/domain/entities/pet.dart';
import '../../domain/entities/health_entry.dart';
import '../providers/occurrence_providers.dart';
import 'care_event_row.dart';
import 'care_event_row_context.dart';
import 'occurrence_care_actions.dart';

/// [CareEventRow] wired to occurrence providers and mark-done stack logic.
class CareEventRowHost extends ConsumerWidget {
  const CareEventRowHost({
    super.key,
    required this.entry,
    this.pet,
    required this.rowContext,
    required this.isCompleted,
    required this.onUndo,
    required this.onView,
    this.onMarkDone,
    this.showTopDivider = true,
  });

  final HealthEntry entry;
  final Pet? pet;
  final CareEventRowContext rowContext;
  final bool isCompleted;
  final VoidCallback onUndo;
  final VoidCallback onView;

  /// When set, invoked instead of the default [OccurrenceCareActions.markDone].
  final Future<void> Function()? onMarkDone;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(occurrenceSummaryProvider(entry.id));
    final occurrencesAsync = ref.watch(entryOccurrencesProvider(entry.id));
    final isMarkDoneEnabled =
        !isCompleted &&
        !occurrencesAsync.isLoading &&
        !occurrencesAsync.hasError;

    return CareEventRow(
      entry: entry,
      pet: pet,
      rowContext: rowContext,
      isCompleted: isCompleted,
      occurrenceSummary: summary,
      showTopDivider: showTopDivider,
      isMarkDoneEnabled: isMarkDoneEnabled,
      onMarkDone: () async {
        if (onMarkDone != null) {
          await onMarkDone!();
          return;
        }
        await OccurrenceCareActions.markDone(context, ref, entry);
      },
      onUndo: onUndo,
      onView: onView,
    );
  }
}
