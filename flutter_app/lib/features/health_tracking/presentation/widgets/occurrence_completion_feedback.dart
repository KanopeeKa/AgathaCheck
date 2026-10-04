import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';
import '../controllers/care_schedule_controller.dart';
import 'care_schedule_command_feedback.dart';
import 'health_issue_prompt/health_issue_linkage_flow.dart';
import 'occurrence_add_details_sheet.dart';

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
    final outcome = await ref
        .read(careScheduleControllerProvider)
        .undoOccurrence(entry.id, occurrenceId);
    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    showCareScheduleCommandSnackBar(
      context,
      outcome: outcome,
      successMessage: l.snackbarUndo,
      failureMessage: l.undoCompleteFailed,
    );
  } catch (_) {
    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.undoCompleteFailed)));
  }
}
