import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/core/utils/calendar_date_picker.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Moves this occurrence's scheduled date (`changeDate` only).
Future<void> rescheduleOccurrenceDate({
  required BuildContext context,
  required WidgetRef ref,
  required OccurrenceDetail detail,
  required Future<void> Function() onChanged,
}) async {
  final l = AppLocalizations.of(context)!;
  final occ = detail.occurrence;
  final today = detail.item.asOf.date;
  final picked = await showCalendarDatePicker(
    context: context,
    initialDate: occ.date.isBefore(today) ? today : occ.date,
    firstDate: today,
    lastDate: DateTime(today.year + 5),
    helpText: l.careNewDateTitle,
  );
  if (picked == null) return;
  final service = ref.read(careCompletionServiceProvider);
  final outcome = await service.changeDate(
    entryId: detail.item.id,
    occurrenceId: occ.id,
    date: picked,
  );
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  switch (outcome) {
    case CareSucceeded():
      await onChanged();
      messenger.showSnackBar(SnackBar(content: Text(l.careDateMoved)));
    case CareFailed(failure: CareNotOpenFailure()):
      messenger.showSnackBar(SnackBar(content: Text(l.careAlreadyUpdated)));
    case CareFailed():
      messenger.showSnackBar(SnackBar(content: Text(l.careCommandFailed)));
  }
}

bool occurrenceShowsReschedule(OccurrenceDetail detail) {
  final occ = detail.occurrence;
  if (!occ.isOpen) return false;
  if (occ.isClosedNotRecorded) return false;
  return true;
}
