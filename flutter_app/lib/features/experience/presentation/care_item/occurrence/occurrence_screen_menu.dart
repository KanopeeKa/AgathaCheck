import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/care_occurrence.dart';

enum OccurrenceScreenMenuAction { postpone, planAnother, addNote }

/// Occurrence ⋯ menu (§18.6.4): Postpone, Plan another date, Add note.
class OccurrenceScreenMenu extends StatelessWidget {
  const OccurrenceScreenMenu({
    super.key,
    required this.occurrenceId,
    required this.onSelected,
    this.muted = false,
  });

  final String occurrenceId;
  final Future<void> Function(OccurrenceScreenMenuAction action) onSelected;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      identifier: 'occurrence_screen_menu_$occurrenceId',
      button: true,
      child: PopupMenuButton<OccurrenceScreenMenuAction>(
        key: Key('occurrence_screen_menu_$occurrenceId'),
        tooltip: l.careOccurrenceMenuTooltip,
        enabled: !muted,
        onSelected: onSelected,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: OccurrenceScreenMenuAction.postpone,
            child: Text(l.careItemMenuPause),
          ),
          PopupMenuItem(
            value: OccurrenceScreenMenuAction.planAnother,
            child: Text(l.carePlanAnotherDate),
          ),
          PopupMenuItem(
            value: OccurrenceScreenMenuAction.addNote,
            child: Text(l.careAddDetails),
          ),
        ],
        icon: const Icon(Icons.more_vert),
      ),
    );
  }
}
