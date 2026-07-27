import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../health_tracking/presentation/widgets/mark_complete_sheet.dart';

/// Shared mark-done / snooze / open helpers for due event cards.
class HomeEventActions {
  const HomeEventActions._();

  static Future<void> markDone(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry,
  ) async {
    final result = await showMarkCompleteSheet(context);
    if (result == null || !context.mounted) return;
    await ref
        .read(healthEntriesNotifierProvider.notifier)
        .markTaken(entry.id, completedOn: result);
    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.markCompletedAction)));
  }

  static Future<void> snoozeDays(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry,
    int days,
  ) async {
    await ref
        .read(healthEntriesNotifierProvider.notifier)
        .snooze(entry.id, days);
    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l.snoozedForDays(entry.name, days, days == 1 ? l.day : l.days),
        ),
      ),
    );
  }

  static void openEntry(BuildContext context, HealthEntry entry) {
    final petId = entry.petId;
    if (petId.isEmpty) return;
    context.push('/pet/$petId/health/edit/${entry.id}');
  }
}
