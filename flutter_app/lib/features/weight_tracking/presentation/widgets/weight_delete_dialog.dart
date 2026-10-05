import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/weight_entry.dart';
import '../providers/weight_providers.dart';

Future<void> confirmDeleteWeightEntry(
  BuildContext context,
  WidgetRef ref, {
  required String petId,
  required WeightEntry entry,
}) async {
  final l = AppLocalizations.of(context)!;
  final fulfils = entry.fulfils;
  final body = fulfils != null
      ? l.weightDeleteLinkedBody(
          fulfils.entryName,
          DateFormat.yMMMd().format(calendarDateOnly(fulfils.scheduledDate)),
        )
      : l.weightDeleteBody;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.weightDeleteTitle),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.delete),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final outcome = await ref
      .read(weightEntriesNotifierProvider(petId).notifier)
      .deleteEntry(entry.id);

  if (!context.mounted) return;
  final reopened = outcome.reopened;
  if (reopened != null && entry.fulfils != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.weightDeletedReopened(entry.fulfils!.entryName)),
      ),
    );
  }
}
