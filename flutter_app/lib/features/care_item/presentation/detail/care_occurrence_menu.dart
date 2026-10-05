import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/care_occurrence.dart';

enum CareOccurrenceMenuAction { skip, postpone, planAnother, addNote }

/// Occurrence menu on the Care Item view (UIR-21, D-CIE-017).
class CareOccurrenceMenu extends StatelessWidget {
  const CareOccurrenceMenu({
    super.key,
    required this.occurrence,
    required this.onSelected,
    this.muted = false,
  });

  final OpenOccurrence occurrence;
  final Future<void> Function(CareOccurrenceMenuAction action) onSelected;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      identifier: 'care_item_occurrence_menu_${occurrence.id}',
      button: true,
      child: PopupMenuButton<CareOccurrenceMenuAction>(
        key: Key('care_item_occurrence_menu_${occurrence.id}'),
        tooltip: l.careOccurrenceMenuTooltip,
        enabled: !muted,
        onSelected: onSelected,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: CareOccurrenceMenuAction.skip,
            child: Text(l.careSkip),
          ),
          PopupMenuItem(
            value: CareOccurrenceMenuAction.postpone,
            child: Text(l.careItemMenuPause),
          ),
          PopupMenuItem(
            value: CareOccurrenceMenuAction.planAnother,
            child: Text(l.carePlanAnotherDate),
          ),
          PopupMenuItem(
            value: CareOccurrenceMenuAction.addNote,
            child: Text(l.careAddDetails),
          ),
        ],
        child: const Icon(Icons.more_vert),
      ),
    );
  }
}
