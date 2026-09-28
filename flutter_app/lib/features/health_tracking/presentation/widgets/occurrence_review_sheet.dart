import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_occurrence.dart';
import 'pet_event_occurrence_actions.dart';
import 'reschedule_occurrence_flow.dart';

/// Bottom sheet to review the open occurrence date (Change date / Skip only).
Future<void> showOccurrenceReviewSheet(
  BuildContext context, {
  required WidgetRef ref,
  required HealthEntry entry,
  required HealthOccurrence occurrence,
  String? absenceId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => OccurrenceReviewSheet(
      entry: entry,
      occurrence: occurrence,
      absenceId: absenceId,
    ),
  );
}

class OccurrenceReviewSheet extends ConsumerWidget {
  const OccurrenceReviewSheet({
    super.key,
    required this.entry,
    required this.occurrence,
    this.absenceId,
  });

  final HealthEntry entry;
  final HealthOccurrence occurrence;
  final String? absenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final dateLabel = formatCalendarDateDisplay(occurrence.scheduledDate);

    return Padding(
      key: const Key('occurrence_review_sheet'),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.careItemOccurrenceReviewTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            l.careItemAbsenceReviewDate(dateLabel),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('occurrence_review_change_date'),
            onPressed: () => _changeDate(context, ref),
            child: Text(l.rescheduleActionLabel),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('occurrence_review_skip'),
            onPressed: () => _skip(context, ref),
            child: Text(l.skipOccurrence),
          ),
        ],
      ),
    );
  }

  Future<void> _changeDate(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);
    if (!context.mounted) return;
    await RescheduleOccurrenceFlow.openSheetAndReschedule(
      context: context,
      ref: ref,
      entry: entry,
      occurrence: occurrence,
      reasonCode: absenceId != null ? 'absence_review' : null,
      absenceId: absenceId,
    );
  }

  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);
    if (!context.mounted) return;
    await PetEventOccurrenceActions.skip(context, ref, entry, occurrence);
  }
}
