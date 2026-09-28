import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/ensure_open_occurrence_result.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_occurrence.dart';
import '../providers/health_providers.dart';
import 'occurrence_review_sheet.dart';
import 'pet_event_occurrence_actions.dart';
import 'reschedule_occurrence_flow.dart';

/// Ensures an open occurrence exists, then shows the review sheet (D-CSM-018).
class OccurrenceReviewFlow {
  const OccurrenceReviewFlow._();

  static Future<void> open(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry, {
    String? absenceId,
    HealthOccurrence? initialOccurrence,
  }) async {
    HealthOccurrence? occurrence = initialOccurrence;
    final needsEnsure = occurrence == null || occurrence.id.isEmpty;

    if (needsEnsure) {
      try {
        final result = await ref
            .read(healthRepositoryProvider)
            .ensureOpenOccurrence(
              entry.id,
              scheduledDate: occurrence?.scheduledDate,
              reasonCode: absenceId != null ? 'absence_review' : null,
            );
        occurrence = pickOccurrenceForReview(result, entry.id);
        PetEventOccurrenceActions.invalidateOccurrenceData(ref, entry.id);
        RescheduleOccurrenceFlow.invalidateAfterReschedule(
          ref,
          entry.id,
          absenceId: absenceId,
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

    if (!context.mounted || occurrence == null || occurrence.id.isEmpty) {
      if (context.mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.careCompletionFailed)),
        );
      }
      return;
    }

    await showOccurrenceReviewSheet(
      context,
      ref: ref,
      entry: entry,
      occurrence: occurrence,
      absenceId: absenceId,
    );
  }

  /// Picks the pending row for the canonical head when ensure-open returns many.
  @visibleForTesting
  static HealthOccurrence? pickOccurrenceForReview(
    EnsureOpenOccurrenceResult result,
    String entryId,
  ) {
    if (result.occurrences.isEmpty) return null;
    final headWire = result.headDate != null
        ? toCalendarDateString(result.headDate!)
        : null;
    if (headWire != null) {
      for (final o in result.occurrences) {
        if (toCalendarDateString(o.scheduledDate) == headWire) {
          return o;
        }
      }
    }
    final pending = result.occurrences.where((o) => o.isPending).toList();
    if (pending.isNotEmpty) {
      pending.sort(
        (a, b) => a.scheduledDate.compareTo(b.scheduledDate),
      );
      return pending.first;
    }
    return result.occurrences.first;
  }
}
