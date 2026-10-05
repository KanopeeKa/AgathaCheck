import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/occurrence_detail.dart';
import '../sheets/plan_another_date_sheet.dart';
import '../sheets/postpone_sheet.dart';
import 'occurrence_screen_menu.dart';

Future<void> handleOccurrenceScreenMenuAction(
  BuildContext context,
  WidgetRef ref,
  OccurrenceDetail detail,
  OccurrenceScreenMenuAction action,
  Future<void> Function() onChanged,
) async {
  final l = AppLocalizations.of(context)!;
  final entryId = detail.item.id;
  final occurrence = detail.occurrence;
  switch (action) {
    case OccurrenceScreenMenuAction.postpone:
      final fixed = detail.item.isFixedSchedule;
      final paused = await showPostponeSheet(
        context,
        ref,
        entryId: entryId,
        isFixedSchedule: fixed,
      );
      if (paused == true) await onChanged();
    case OccurrenceScreenMenuAction.planAnother:
      final added = await showPlanAnotherDateSheet(
        context,
        ref,
        entryId: entryId,
        initialDate: occurrence.date,
      );
      if (added == true) await onChanged();
    case OccurrenceScreenMenuAction.addNote:
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.careAddDetails)));
  }
}
