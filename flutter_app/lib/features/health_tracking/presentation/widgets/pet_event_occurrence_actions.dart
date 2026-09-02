import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_occurrence.dart';
import '../providers/health_providers.dart';
import '../providers/occurrence_providers.dart';
import 'mark_complete_sheet.dart';
import 'occurrence_care_actions.dart';
import 'pet_event_view_providers.dart';

/// Occurrence mutations from the event-view workbench.
class PetEventOccurrenceActions {
  const PetEventOccurrenceActions._();

  static void invalidateOccurrenceData(WidgetRef ref, String entryId) {
    ref.invalidate(entryOccurrencesProvider(entryId));
    ref.invalidate(entryPastOccurrencesProvider(entryId));
    ref.invalidate(entryHistoryProvider(entryId));
  }

  static Future<void> markDone(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry,
    HealthOccurrence occurrence,
  ) async {
    final completedOn = await showMarkCompleteSheet(context);
    if (completedOn == null || !context.mounted) return;

    try {
      await OccurrenceCareActions.persistCompletion(
        ref,
        entry,
        completedOn,
        occurrenceId: occurrence.id,
      );
      invalidateOccurrenceData(ref, entry.id);
    } catch (_) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.careCompletionFailed)),
      );
      return;
    }

    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.markCompletedAction)),
    );
  }

  static Future<void> skip(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry,
    HealthOccurrence occurrence,
  ) async {
    try {
      await ref
          .read(healthRepositoryProvider)
          .skipOccurrence(entry.id, occurrence.id);
      invalidateOccurrenceData(ref, entry.id);
      await ref.read(healthEntriesNotifierProvider.notifier).refresh();
    } catch (_) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.careCompletionFailed)),
      );
      return;
    }

    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.occurrenceSkipped)),
    );
  }

  static Future<void> skipAllMissed(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry,
  ) async {
    try {
      await OccurrenceCareActions.skipAllMissed(ref, entry);
      invalidateOccurrenceData(ref, entry.id);
    } catch (_) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.careCompletionFailed)),
      );
      return;
    }

    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.occurrenceSkipped)),
    );
  }
}
