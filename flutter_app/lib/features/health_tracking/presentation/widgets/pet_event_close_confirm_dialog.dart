import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// User choice from the Close care confirmation dialog (CARE-STATUS-R-016).
enum CloseCareDialogResult { cancel, recordFirst, confirmClose }

/// Confirms closing a care item; offers [CloseCareDialogResult.recordFirst]
/// when [startedOpenCount] is greater than zero.
Future<CloseCareDialogResult?> showCloseCareConfirmDialog(
  BuildContext context, {
  required int startedOpenCount,
}) {
  final l = AppLocalizations.of(context)!;
  final notRecordedLine = startedOpenCount > 0
      ? l.careCloseConfirmStartedDates(startedOpenCount)
      : null;

  return showDialog<CloseCareDialogResult>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.careCloseConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.careCloseConfirmNoReopen),
          if (notRecordedLine != null) ...[
            const SizedBox(height: 12),
            Text(notRecordedLine),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(CloseCareDialogResult.cancel),
          child: Text(l.cancel),
        ),
        if (startedOpenCount > 0)
          Semantics(
            identifier: 'care_close_record_first_button',
            button: true,
            child: TextButton(
              key: const Key('care_close_record_first_button'),
              onPressed: () =>
                  Navigator.of(ctx).pop(CloseCareDialogResult.recordFirst),
              child: Text(l.careCloseConfirmRecordFirst),
            ),
          ),
        Semantics(
          identifier: 'care_close_confirm_button',
          button: true,
          child: FilledButton(
            key: const Key('care_close_confirm_button'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () =>
                Navigator.of(ctx).pop(CloseCareDialogResult.confirmClose),
            child: Text(l.careCloseConfirmAction),
          ),
        ),
      ],
    ),
  );
}
