import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_occurrence.dart';
import '../controllers/care_schedule_controller.dart';
import '../providers/care_item_detail_refresh.dart';
import 'care_schedule_command_feedback.dart';
import 'occurrence_care_actions.dart';
import 'occurrence_completion_date_flow.dart';
import 'occurrence_completion_feedback.dart';
import 'reschedule_occurrence_flow.dart';
import 'weight_occurrence_care_actions.dart';

/// Occurrence mutations from the event-view workbench.
class PetEventOccurrenceActions {
  const PetEventOccurrenceActions._();

  static void invalidateOccurrenceData(
    WidgetRef ref,
    String entryId, {
    String? absenceId,
  }) {
    invalidateCareItemDetailData(ref, entryId, absenceId: absenceId);
  }

  static Future<void> markDone(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry,
    HealthOccurrence occurrence,
  ) async {
    if (WeightOccurrenceCareActions.isWeightRhythm(entry)) {
      try {
        final saved =
            await WeightOccurrenceCareActions.showWeightEntrySheetForOccurrence(
              context,
              ref,
              entry,
              occurrence.id,
            );
        if (!saved || !context.mounted) return;
      } catch (_) {
        if (!context.mounted) return;
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.careCompletionFailed)));
        return;
      }

      if (!context.mounted) return;
      await showOccurrenceCompletionFeedback(
        context,
        ref,
        entry: entry,
        occurrenceId: occurrence.id,
        promptHealthIssue: false,
      );
      return;
    }

    final completedOn = await resolveCompletedOnForOccurrence(
      context,
      occurrence,
    );
    if (completedOn == null || !context.mounted) return;

    try {
      final outcome = await OccurrenceCareActions.persistCompletion(
        ref,
        entry,
        completedOn,
        occurrenceId: occurrence.id,
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

    if (!context.mounted) return;
    await showOccurrenceCompletionFeedback(
      context,
      ref,
      entry: entry,
      occurrenceId: occurrence.id,
    );
  }

  static Future<void> changeDate(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry,
    HealthOccurrence occurrence, {
    DateTime? initialDate,
    String? reasonCode,
  }) {
    return RescheduleOccurrenceFlow.openSheetAndReschedule(
      context: context,
      ref: ref,
      entry: entry,
      occurrence: occurrence,
      initialDate: initialDate,
      reasonCode: reasonCode,
    );
  }

  static Future<void> skip(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry,
    HealthOccurrence occurrence, {
    String? absenceId,
  }) async {
    try {
      final outcome = await ref
          .read(careScheduleControllerProvider)
          .skipOccurrence(entry.id, occurrence.id, absenceId: absenceId);
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      showCareScheduleCommandSnackBar(
        context,
        outcome: outcome,
        successMessage: l.occurrenceSkipped,
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

  static Future<void> skipAllMissed(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry,
  ) async {
    try {
      final outcome = await OccurrenceCareActions.skipAllMissed(ref, entry);
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      showCareScheduleCommandSnackBar(
        context,
        outcome: outcome,
        successMessage: l.occurrenceSkipped,
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
}
