import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/command_outcome.dart';

/// Snackbar feedback for [CareScheduleController] commands (G.3-3).
void showCareScheduleCommandSnackBar(
  BuildContext context, {
  required CommandOutcome? outcome,
  required String successMessage,
  String? failureMessage,
}) {
  if (outcome == null) return;
  final l = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  if (!outcome.committed) {
    messenger.showSnackBar(
      SnackBar(content: Text(failureMessage ?? l.careCompletionFailed)),
    );
    return;
  }
  if (outcome.refreshFailed) {
    messenger.showSnackBar(
      SnackBar(content: Text(l.careCommandSavedRefreshFailed)),
    );
    return;
  }
  messenger.showSnackBar(SnackBar(content: Text(successMessage)));
}
