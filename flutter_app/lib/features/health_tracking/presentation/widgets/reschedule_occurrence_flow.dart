import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../../pet_care/context/domain/entities/care_period_coverage.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_occurrence.dart';
import '../../domain/services/reschedule_occurrence_preview.dart';
import '../controllers/care_schedule_controller.dart';
import '../providers/care_item_absence_providers.dart';
import '../providers/care_item_absence_resolution_sync.dart';
import '../providers/pet_event_view_providers.dart';
import 'care_schedule_command_feedback.dart';
import 'reschedule_occurrence_sheet.dart';
import 'reschedule_warning_copy.dart';

/// Shared reschedule + undo snackbar (R-C5, R-C7).
class RescheduleOccurrenceFlow {
  const RescheduleOccurrenceFlow._();

  static Future<void> fromAwayPlanRow({
    required BuildContext context,
    required WidgetRef ref,
    required PlannedCareItem item,
    required String startsOn,
    required String endsOn,
    required String absenceId,
  }) async {
    final occId = item.resolvedOccurrenceId;
    final sched = item.openOccurrence?.scheduledDate ?? item.scheduledDate;
    if (occId == null || sched == null) return;

    final entry = await ref
        .read(careScheduleControllerProvider)
        .getEntry(item.healthEntryId);
    if (entry == null || !context.mounted) return;

    final occurrence = HealthOccurrence(
      id: occId,
      entryId: item.healthEntryId,
      scheduledDate: parseCalendarDate(sched)!,
      scheduledTime: item.openOccurrence?.scheduledTime,
      status: 'pending',
    );

    final today = calendarDateOnly(DateTime.now());
    final past = await ref
        .read(entryPastOccurrencesProvider(entry.id).future)
        .catchError((_) => <HealthOccurrence>[]);
    final lastClosed = lastClosedReferenceDate(entry, past);
    final bounds = reschedulePickerBounds(
      entry: entry,
      occurrence: occurrence,
      today: today,
      lastClosedDate: lastClosed,
    );
    final prefill = awayPlanReschedulePrefillDate(
      startsOn: startsOn,
      endsOn: endsOn,
      today: today,
      minDate: bounds.firstDate,
      maxDate: bounds.lastDate,
    );

    await openSheetAndReschedule(
      context: context,
      ref: ref,
      entry: entry,
      occurrence: occurrence,
      initialDate: prefill,
      reasonCode: 'away_planner',
      absenceId: absenceId,
    );
  }

  static Future<void> openSheetAndReschedule({
    required BuildContext context,
    required WidgetRef ref,
    required HealthEntry entry,
    required HealthOccurrence occurrence,
    DateTime? initialDate,
    String? reasonCode,
    String? absenceId,
  }) async {
    final past = await ref
        .read(entryPastOccurrencesProvider(entry.id).future)
        .catchError((_) => <HealthOccurrence>[]);

    final newDate = await showRescheduleOccurrenceSheet(
      context,
      entry: entry,
      occurrence: occurrence,
      pastOccurrences: past,
      initialDate: initialDate,
    );
    if (newDate == null || !context.mounted) return;

    final scheduledDate = calendarDateOnly(newDate);

    try {
      final command = await ref
          .read(careScheduleControllerProvider)
          .rescheduleOccurrence(
            entry.id,
            occurrence.id,
            scheduledDate,
            reasonCode: reasonCode,
            absenceId: absenceId,
          );
      if (command == null || !context.mounted) return;

      if (absenceId != null && absenceId.isNotEmpty) {
        await _syncResolutionAfterReschedule(
          ref,
          entry.id,
          absenceId: absenceId,
          newScheduledDate: toCalendarDateString(
            calendarDateOnly(scheduledDate),
          )!,
        );
      }

      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      final warningText = rescheduleWarningMessages(l, command.result.warnings);
      final successMessage = warningText.isNotEmpty
          ? warningText.join('\n')
          : l.occurrenceRescheduled;

      if (command.outcome.refreshFailed) {
        showCareScheduleCommandSnackBar(
          context,
          outcome: command.outcome,
          successMessage: successMessage,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            action: SnackBarAction(
              label: l.snackbarUndo,
              onPressed: () => _undoReschedule(
                context,
                ref,
                entry.id,
                occurrence.id,
                absenceId: absenceId,
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.careCompletionFailed)));
    }
  }

  static Future<void> _syncResolutionAfterReschedule(
    WidgetRef ref,
    String entryId, {
    required String absenceId,
    required String newScheduledDate,
  }) async {
    final contextModel = await ref.read(
      careItemAbsenceContextProvider(entryId).future,
    );
    final slice = contextModel.absences
        .where((s) => s.plannedAbsenceId == absenceId)
        .firstOrNull;
    if (slice == null) return;
    final decision = inferResolutionDecisionAfterReschedule(
      newScheduledDate: newScheduledDate,
      absenceStartsOn: slice.startsOn,
      absenceEndsOn: slice.endsOn,
    );
    if (decision == null) return;
    final remote = ref.read(healthAbsenceContextRemoteProvider);
    await syncAbsenceResolution(
      remote: remote,
      slice: slice,
      healthEntryId: entryId,
      decision: decision,
    );
  }

  static Future<void> _undoReschedule(
    BuildContext context,
    WidgetRef ref,
    String entryId,
    String occurrenceId, {
    String? absenceId,
  }) async {
    try {
      final outcome = await ref
          .read(careScheduleControllerProvider)
          .undoOccurrence(
            entryId,
            occurrenceId,
            absenceId: absenceId,
          );
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      showCareScheduleCommandSnackBar(
        context,
        outcome: outcome,
        successMessage: l.snackbarUndo,
      );
    } catch (_) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.careCompletionFailed)));
    }
  }
}
