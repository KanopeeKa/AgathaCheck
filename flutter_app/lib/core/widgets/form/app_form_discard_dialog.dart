import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Returns true when the user confirms discarding unsaved changes.
///
/// Pass [title], [body], and [discardLabel] for form-specific copy (e.g. pet
/// profile). Defaults to neutral strings suitable for any edit form.
Future<bool> confirmDiscardFormChanges(
  BuildContext context, {
  String? title,
  String? body,
  String? discardLabel,
}) async {
  final l = AppLocalizations.of(context)!;
  final discard = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title ?? l.formUnsavedTitle),
      content: Text(body ?? l.formUnsavedBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(discardLabel ?? l.formDiscard),
        ),
      ],
    ),
  );
  return discard ?? false;
}
