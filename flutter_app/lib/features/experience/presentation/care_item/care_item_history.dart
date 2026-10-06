import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';

Future<void> showPetEventHistory(
  BuildContext context,
  WidgetRef ref,
  String entryId,
) async {
  final l = AppLocalizations.of(context)!;
  try {
    final history = await ref.read(entryHistoryProvider(entryId).future);
    if (!context.mounted) return;
    await showPetEventAdministrationHistoryDialog(context, history: history);
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.failedToLoadHistory('$error'))));
  }
}
