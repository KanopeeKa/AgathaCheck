import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Editable handover-note field used on the Away Plan edit screen
/// (`/pc/away/:id/edit`).
///
/// Save lives in the screen's sticky/inline actions bar per D-AWD-007
/// (`AppFormStickyActionsBar` / `AppFormActionsBar`), so this widget owns
/// only the field itself, not a submit button — split out of the old inline
/// `AwayPlanHandoverNoteSection` editor (D-AWD-007's `file-split` allowance).
class AwayPlanHandoverNoteEditor extends StatelessWidget {
  const AwayPlanHandoverNoteEditor({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
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
            child: TextField(
              key: const Key('away_plan_handover_note'),
              controller: controller,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: l.pdfNotesLabel,
                alignLabelWithHint: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
