import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';
import '../providers/health_providers.dart';
import '../providers/occurrence_providers.dart';
import 'health_issue_prompt/health_issue_linkage_flow.dart';
import 'occurrence_add_details_sheet.dart';
import 'pet_event_occurrence_actions.dart';

/// Post-completion snackbar: Done · Add details · Undo (D-CIE-009).
Future<void> showOccurrenceCompletionFeedback(
  BuildContext context,
  WidgetRef ref, {
  required HealthEntry entry,
  required String occurrenceId,
  bool promptHealthIssue = true,
}) async {
  if (!context.mounted) return;
  final l = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);

  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Expanded(
            child: Text(
              l.done,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            key: const Key('occurrence_completion_add_details'),
            onPressed: () {
              messenger.hideCurrentSnackBar();
              showOccurrenceAddDetailsSheet(
                context,
                ref,
                entry: entry,
                occurrenceId: occurrenceId,
              );
            },
            child: Text(l.careAddDetails),
          ),
          TextButton(
            key: const Key('occurrence_completion_undo'),
            onPressed: () async {
              messenger.hideCurrentSnackBar();
              await _undoOccurrenceCompletion(
                context,
                ref,
                entry,
                occurrenceId,
              );
            },
            child: Text(l.snackbarUndo),
          ),
        ],
      ),
      duration: const Duration(seconds: 8),
    ),
  );

  if (promptHealthIssue && context.mounted) {
    await HealthIssueLinkageFlow.maybePromptAfterPlannedVetCompletion(
      context,
      ref,
      entry,
    );
  }
}

Future<void> _undoOccurrenceCompletion(
  BuildContext context,
  WidgetRef ref,
  HealthEntry entry,
  String occurrenceId,
) async {
  try {
    await ref
        .read(healthRepositoryProvider)
        .undoOccurrence(entry.id, occurrenceId);
    PetEventOccurrenceActions.invalidateOccurrenceData(ref, entry.id);
    await ref.read(healthEntriesNotifierProvider.notifier).refresh();
  } catch (_) {
    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.undoCompleteFailed)));
  }
}
