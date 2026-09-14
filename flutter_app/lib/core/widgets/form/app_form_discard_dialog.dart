import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Returns true when the user confirms discarding unsaved changes.
Future<bool> confirmDiscardFormChanges(BuildContext context) async {
  final l = AppLocalizations.of(context)!;
  final discard = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.petFormUnsavedTitle),
      content: Text(l.petFormUnsavedBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.petFormDiscard),
        ),
      ],
    ),
  );
  return discard ?? false;
}
