import 'package:flutter/material.dart';

import '../../../../core/router/shell_return_navigation.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_occurrence.dart';
import 'past_occurrence_history_pill.dart';

const double _kHistoryDialogMaxHeight = 420;

/// Scrollable full history pop-up (same shell as legacy administration log).
Future<void> showPetEventPastHistoryDialog(
  BuildContext context, {
  required List<HealthOccurrence> occurrences,
  required String petId,
  required bool muted,
}) {
  final l = AppLocalizations.of(context)!;
  final maxHeight = MediaQuery.sizeOf(context).height * 0.55;

  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        key: const Key('pet_event_history_dialog'),
        title: Text(l.careItemHistoryTitle),
        content: SizedBox(
          width: double.maxFinite,
          height: maxHeight.clamp(200, _kHistoryDialogMaxHeight),
          child: occurrences.isEmpty
              ? Align(alignment: Alignment.topLeft, child: Text(l.noHistoryYet))
              : ListView.builder(
                  itemCount: occurrences.length,
                  itemBuilder: (_, i) {
                    final occ = occurrences[i];
                    return PastOccurrenceHistoryPill(
                      occurrence: occ,
                      muted: muted,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        openOccurrenceScreen(
                          context,
                          petId: petId,
                          entryId: occ.entryId,
                          occurrenceId: occ.id,
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            key: const Key('pet_event_history_dialog_close'),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.close),
          ),
        ],
      );
    },
  );
}
