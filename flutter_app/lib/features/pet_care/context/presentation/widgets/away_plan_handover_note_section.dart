import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/planned_absence.dart';

/// Read-only display of the handover note on the Away Plan detail screen.
///
/// Per D-AWD-007, note editing moved to the edit screen
/// (`AwayPlanHandoverNoteEditor`, `/pc/away/:id/edit`). This widget only
/// shows the note when one is present — rendering nothing (not an empty
/// "Notes" header) when there isn't one, so a returning pet parent or carer
/// sees the note without entering edit mode, and no dangling header when
/// there's nothing to show.
class AwayPlanHandoverNoteSection extends StatelessWidget {
  const AwayPlanHandoverNoteSection({super.key, required this.absence});

  final PlannedAbsence absence;

  @override
  Widget build(BuildContext context) {
    final note = absence.handoverNote;
    if (note == null || note.trim().isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.pdfNotesLabel, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Semantics(
              identifier: 'away_plan_handover_note_text',
              label: note,
              child: Text(note, key: const Key('away_plan_handover_note_text')),
            ),
          ),
        ),
      ],
    );
  }
}
