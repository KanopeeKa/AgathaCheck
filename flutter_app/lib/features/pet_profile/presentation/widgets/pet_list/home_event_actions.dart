import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../health_tracking/presentation/widgets/mark_complete_sheet.dart';

/// Shared mark-done / snooze helpers for compact home event rows.
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

  static Future<void> snooze(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry,
  ) async {
    final l = AppLocalizations.of(context)!;
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) {
        var selected = 1;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text('${l.snooze} ${entry.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [1, 3, 7, 14].map((d) {
                return RadioListTile<int>(
                  value: d,
                  groupValue: selected,
                  title: Text(l.snoozeDays(d, d == 1 ? l.day : l.days)),
                  onChanged: (v) => setState(() => selected = v ?? selected),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, selected),
                child: Text(l.snooze),
              ),
            ],
          ),
        );
      },
    );
    if (days == null || !context.mounted) return;
    await ref
        .read(healthEntriesNotifierProvider.notifier)
        .snooze(entry.id, days);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l.snoozedForDays(entry.name, days, days == 1 ? l.day : l.days),
        ),
      ),
    );
  }

  static void openPet(BuildContext context, String? petId) {
    if (petId == null || petId.isEmpty) return;
    context.push('/pet/$petId');
  }
}
