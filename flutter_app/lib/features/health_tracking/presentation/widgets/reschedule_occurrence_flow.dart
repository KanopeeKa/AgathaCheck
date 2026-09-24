import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_care/context/presentation/providers/care_context_providers.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../../pet_care/context/domain/entities/care_period_coverage.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_occurrence.dart';
import '../../domain/services/reschedule_occurrence_preview.dart';
import '../providers/health_providers.dart';
import '../providers/occurrence_providers.dart';
import 'pet_event_view_providers.dart';
import 'reschedule_occurrence_sheet.dart';
import 'reschedule_warning_copy.dart';

/// Shared reschedule + invalidation + undo snackbar (R-C5, R-C7).
class RescheduleOccurrenceFlow {
  const RescheduleOccurrenceFlow._();

  static Future<void> fromAwayPlanRow({
    required BuildContext context,
    required WidgetRef ref,
    required PlannedCareItem item,
    required String startsOn,
    required String endsOn,
  }) async {
    final occId = item.openOccurrence?.occurrenceId ?? item.occurrenceId;
    final sched =
        item.openOccurrence?.scheduledDate ?? item.scheduledDate;
    if (occId == null || sched == null) return;

    final entry = await ref
        .read(healthRepositoryProvider)
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
    );
  }

  static Future<void> openSheetAndReschedule({
    required BuildContext context,
    required WidgetRef ref,
    required HealthEntry entry,
    required HealthOccurrence occurrence,
    DateTime? initialDate,
    String? reasonCode,
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

    try {
      final result = await ref
          .read(healthRepositoryProvider)
          .rescheduleOccurrence(
            entry.id,
            occurrence.id,
            newDate,
            reasonCode: reasonCode,
          );
      _invalidateAfterReschedule(ref, entry.id);
      await ref.read(healthEntriesNotifierProvider.notifier).refresh();

      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      final warningText = rescheduleWarningMessages(l, result.warnings);
      final message = warningText.isNotEmpty
          ? warningText.join('\n')
          : l.occurrenceRescheduled;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: l.snackbarUndo,
            onPressed: () => _undoReschedule(
              context,
              ref,
              entry.id,
              occurrence.id,
            ),
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.careCompletionFailed)));
    }
  }

  static void _invalidateAfterReschedule(WidgetRef ref, String entryId) {
    ref.invalidate(entryOccurrencesProvider(entryId));
    ref.invalidate(entryPastOccurrencesProvider(entryId));
    ref.invalidate(entryHistoryProvider(entryId));
    ref.invalidate(carePeriodCoverageProvider);
  }

  static Future<void> _undoReschedule(
    BuildContext context,
    WidgetRef ref,
    String entryId,
    String occurrenceId,
  ) async {
    try {
      await ref
          .read(healthRepositoryProvider)
          .undoOccurrence(entryId, occurrenceId);
      _invalidateAfterReschedule(ref, entryId);
      await ref.read(healthEntriesNotifierProvider.notifier).refresh();
    } catch (_) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.careCompletionFailed)));
    }
  }
}
