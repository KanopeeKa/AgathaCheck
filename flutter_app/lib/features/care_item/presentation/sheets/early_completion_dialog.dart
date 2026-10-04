import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';

/// DN-4 / UIR-10: "Planned for 12 Mar. Mark it as done today?" — Cancel
/// first; Cancel saves nothing.
Future<bool> showEarlyCompletionDialog(
  BuildContext context, {
  required DateTime plannedFor,
}) async {
  final l = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('early_completion_dialog'),
      content: Text(
        l.careEarlyCompletionBody(DateFormat.MMMd().format(plannedFor)),
      ),
      actions: [
        TextButton(
          key: const Key('early_completion_cancel'),
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('early_completion_confirm'),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.markAsDone),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
