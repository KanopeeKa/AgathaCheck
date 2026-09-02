import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_occurrence.dart';
import '../../domain/occurrence_scheduling.dart';
import '../providers/health_providers.dart';
import '../providers/occurrence_providers.dart';
import 'mark_complete_sheet.dart';
import 'occurrence_stack_sheet.dart';

/// Occurrence-aware mark-done, stack sheet, and bulk skip helpers for list surfaces.
class OccurrenceCareActions {
  const OccurrenceCareActions._();

  /// Shows stack sheet or mark-complete sheet; returns null when dismissed.
  static Future<OccurrenceMarkDoneResult?> showMarkDoneFlow(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry,
  ) async {
    List<HealthOccurrence> occurrences;
    try {
      occurrences = await ref.read(entryOccurrencesProvider(entry.id).future);
    } catch (_) {
      final completedOn = await showMarkCompleteSheet(context);
      if (completedOn == null || !context.mounted) return null;
      return OccurrenceMarkDoneResult(completedOn: completedOn);
    }

    final summary = summarizeOpenOccurrences(occurrences, DateTime.now());

    if (summary.openCount > 1 || summary.missedCount >= 1) {
      final stackResult = await showOccurrenceStackSheet(
        context,
        entry: entry,
        occurrences: occurrences,
        onRecordHead: (occurrenceId, completedOn, skipEarlierMissed) async {
          await persistCompletion(
            ref,
            entry,
            completedOn,
            occurrenceId: occurrenceId,
            skipEarlierMissed: skipEarlierMissed,
          );
        },
        onSkipAllMissed: () async {
          await skipAllMissed(ref, entry);
        },
      );
      if (stackResult == null || !context.mounted) return null;
      return stackResult;
    }

    if (summary.openCount == 1) {
      final completedOn = await showMarkCompleteSheet(context);
      if (completedOn == null || !context.mounted) return null;
      return OccurrenceMarkDoneResult(
        completedOn: completedOn,
        occurrenceId: occurrences.first.id,
      );
    }

    final completedOn = await showMarkCompleteSheet(context);
    if (completedOn == null || !context.mounted) return null;
    return OccurrenceMarkDoneResult(completedOn: completedOn);
  }

  /// Persists completion via occurrence API or legacy mark-taken.
  static Future<void> persistCompletion(
    WidgetRef ref,
    HealthEntry entry,
    DateTime completedOn, {
    String? occurrenceId,
    bool skipEarlierMissed = false,
  }) async {
    if (occurrenceId != null) {
      await ref.read(healthRepositoryProvider).completeOccurrence(
        entry.id,
        occurrenceId,
        completedOn: completedOn,
        skipEarlierMissed: skipEarlierMissed,
      );
      ref.invalidate(entryOccurrencesProvider(entry.id));
      await ref.read(healthEntriesNotifierProvider.notifier).refresh();
      return;
    }

    await ref
        .read(healthEntriesNotifierProvider.notifier)
        .markTaken(entry.id, completedOn: completedOn);
  }

  /// Skips every missed open occurrence for [entry].
  static Future<void> skipAllMissed(WidgetRef ref, HealthEntry entry) async {
    await ref.read(healthRepositoryProvider).skipMissedOccurrences(entry.id);
    ref.invalidate(entryOccurrencesProvider(entry.id));
    await ref.read(healthEntriesNotifierProvider.notifier).refresh();
  }

  /// Direct mark-done with snackbar (pet due sections without optimistic state).
  static Future<void> markDone(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry,
  ) async {
    final result = await showMarkDoneFlow(context, ref, entry);
    if (result == null || !context.mounted) return;

    if (!result.alreadyPersisted) {
      try {
        await persistCompletion(
          ref,
          entry,
          result.completedOn,
          occurrenceId: result.occurrenceId,
          skipEarlierMissed: result.skipEarlierMissed,
        );
      } catch (_) {
        if (!context.mounted) return;
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.careCompletionFailed)),
        );
        return;
      }
    }

    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.markCompletedAction)),
    );
  }
}
