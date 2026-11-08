import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';

Future<void> showPetEventHistory(
  BuildContext context,
  WidgetRef ref, {
  required String petId,
  required String entryId,
  required bool muted,
}) async {
  final l = AppLocalizations.of(context)!;
  try {
    final past = await ref.read(entryPastOccurrencesProvider(entryId).future);
    if (!context.mounted) return;
    await showPetEventPastHistoryDialog(
      context,
      occurrences: resolvedPastOccurrences(past),
      petId: petId,
      muted: muted,
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.failedToLoadHistory('$error'))));
  }
}
