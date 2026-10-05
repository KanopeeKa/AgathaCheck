import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_occurrence.dart';
import '../providers/occurrence_providers.dart';
import 'occurrence_review_sheet.dart';

/// Loads the open occurrence head when needed, then shows the review sheet.
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
    final needsLoad = occurrence == null || occurrence.id.isEmpty;

    if (needsLoad) {
      try {
        final open = await ref.read(entryOccurrencesProvider(entry.id).future);
        occurrence = pickOccurrenceForReview(
          open,
          preferredDate: occurrence?.scheduledDate,
        );
      } catch (_) {
        if (!context.mounted) return;
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.careCompletionFailed)));
        return;
      }
    }

    if (!context.mounted || occurrence == null || occurrence.id.isEmpty) {
      if (context.mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.careCompletionFailed)));
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

  /// Picks the pending row for the canonical head when many are open.
  @visibleForTesting
  static HealthOccurrence? pickOccurrenceForReview(
    List<HealthOccurrence> occurrences, {
    DateTime? preferredDate,
  }) {
    if (occurrences.isEmpty) return null;
    if (preferredDate != null) {
      final wire = toCalendarDateString(preferredDate);
      for (final o in occurrences) {
        if (o.isPending && toCalendarDateString(o.scheduledDate) == wire) {
          return o;
        }
      }
    }
    final pending = occurrences.where((o) => o.isPending).toList();
    if (pending.isNotEmpty) {
      pending.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      return pending.first;
    }
    return occurrences.first;
  }
}
