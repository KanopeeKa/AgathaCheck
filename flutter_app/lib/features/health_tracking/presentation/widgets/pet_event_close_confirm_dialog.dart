import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Confirms closing a care event when associated occurrences will also close.
Future<bool?> showCloseEventConfirmDialog(
  BuildContext context, {
  required int openOccurrenceCount,
}) {
  final l = AppLocalizations.of(context)!;
  final message = openOccurrenceCount > 0
      ? l.closeEventConfirmMessageWithCount(openOccurrenceCount)
      : l.closeEventConfirmMessage;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.closeEventConfirmTitle),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('pet_event_close_confirm_button'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l.closeEventAction),
        ),
      ],
    ),
  );
}
