import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/shell_return_navigation.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/pet_profile.dart';
import '../../domain/entities/command_outcome.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_occurrence.dart';
import '../../domain/occurrence_scheduling.dart';
import '../controllers/care_schedule_controller.dart';
import '../providers/occurrence_providers.dart';
import 'care_schedule_command_feedback.dart';
import 'health_issue_prompt/health_issue_linkage_flow.dart';
import 'occurrence_completion_date_flow.dart';
import 'occurrence_completion_feedback.dart';
import 'occurrence_stack_sheet.dart';

/// Occurrence-aware mark-done, stack sheet, and bulk skip helpers for list surfaces.
class OccurrenceCareActions {
  const OccurrenceCareActions._();

  static bool _isWeightMonitoring(HealthEntry entry) =>
      entry.careFamily == CareFamily.weightMonitoring;

  /// Shows stack sheet or mark-complete sheet; returns null when dismissed.
  static Future<OccurrenceMarkDoneResult?> showMarkDoneFlow(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry,
  ) async {
    if (_isWeightMonitoring(entry)) {
      return _openWeightOccurrenceScreen(context, ref, entry);
    }

    List<HealthOccurrence> occurrences;
    try {
      occurrences = await ref.read(entryOccurrencesProvider(entry.id).future);
    } catch (_) {
      return null;
    }

    final now = DateTime.now();
    final summary = summarizeOpenOccurrences(occurrences, now);

    if (_shouldShowOccurrenceStack(occurrences, summary, now)) {
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
      final head = occurrences.first;
      final completedOn = await resolveCompletedOnForOccurrence(context, head);
      if (completedOn == null || !context.mounted) return null;
      return OccurrenceMarkDoneResult(
        completedOn: completedOn,
        occurrenceId: head.id,
      );
    }

    final head = summary.leadingOccurrence;
    if (head == null) return null;
    final completedOn = await resolveCompletedOnForOccurrence(context, head);
    if (completedOn == null || !context.mounted) return null;
    return OccurrenceMarkDoneResult(
      completedOn: completedOn,
      occurrenceId: head.id,
    );
  }

  /// Persists completion via [CareScheduleController].
  static Future<CommandOutcome?> persistCompletion(
    WidgetRef ref,
    HealthEntry entry,
    DateTime completedOn, {
    String? occurrenceId,
    bool skipEarlierMissed = false,
  }) async {
    final id = occurrenceId;
    if (id == null || id.isEmpty) {
      throw StateError('occurrenceId is required to complete care');
    }
    return ref
        .read(careScheduleControllerProvider)
        .completeOccurrence(
          entry.id,
          id,
          completedOn: completedOn,
          skipEarlierMissed: skipEarlierMissed,
        );
  }

  /// Skips every missed open occurrence for [entry].
  static Future<CommandOutcome?> skipAllMissed(
    WidgetRef ref,
    HealthEntry entry,
  ) async {
    return ref
        .read(careScheduleControllerProvider)
        .skipAllMissedOccurrences(entry.id);
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
        final outcome = await persistCompletion(
          ref,
          entry,
          result.completedOn,
          occurrenceId: result.occurrenceId,
          skipEarlierMissed: result.skipEarlierMissed,
        );
        if (!context.mounted) return;
        final l = AppLocalizations.of(context)!;
        showCareScheduleCommandSnackBar(
          context,
          outcome: outcome,
          successMessage: l.markCompletedAction,
        );
        if (outcome == null) return;
      } catch (_) {
        if (!context.mounted) return;
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.careCompletionFailed)));
        return;
      }
    }

    if (!context.mounted) return;
    final occurrenceId = result.occurrenceId;
    if (occurrenceId != null) {
      await showOccurrenceCompletionFeedback(
        context,
        ref,
        entry: entry,
        occurrenceId: occurrenceId,
      );
      return;
    }
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.markCompletedAction)));
    await HealthIssueLinkageFlow.maybePromptAfterPlannedVetCompletion(
      context,
      ref,
      entry,
    );
  }

  static Future<OccurrenceMarkDoneResult?> _openWeightOccurrenceScreen(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry,
  ) async {
    List<HealthOccurrence> occurrences;
    try {
      occurrences = await ref.read(entryOccurrencesProvider(entry.id).future);
    } catch (_) {
      return null;
    }

    final now = DateTime.now();
    final summary = summarizeOpenOccurrences(occurrences, now);
    if (summary.openCount == 0) return null;

    if (_shouldShowOccurrenceStack(occurrences, summary, now)) {
      await showOccurrenceStackSheet(
        context,
        entry: entry,
        occurrences: occurrences,
        onRecordHead: (occurrenceId, _, skipEarlierMissed) async {
          if (skipEarlierMissed) {
            await skipAllMissed(ref, entry);
          }
          if (!context.mounted) return;
          openOccurrenceScreen(
            context,
            petId: entry.petId,
            entryId: entry.id,
            occurrenceId: occurrenceId,
            focus: 'weight',
          );
        },
        onSkipAllMissed: () async {
          await skipAllMissed(ref, entry);
        },
      );
      return null;
    }

    if (!context.mounted) return null;
    openOccurrenceScreen(
      context,
      petId: entry.petId,
      entryId: entry.id,
      occurrenceId: occurrences.first.id,
      focus: 'weight',
    );
    return null;
  }

  static bool _shouldShowOccurrenceStack(
    List<HealthOccurrence> occurrences,
    OccurrenceSummary summary,
    DateTime now,
  ) {
    if (summary.missedCount > 0) return true;
    return occurrences
            .where(
              (occurrence) =>
                  occurrence.isPending &&
                  occurrenceZone(occurrence, now) == OccurrenceZone.dueToday,
            )
            .length >
        1;
  }
}
