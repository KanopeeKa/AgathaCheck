import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/health_entry.dart';

/// Care item overflow menu (D-CIE-017): Edit, Pause/Resume, Archive/Restore.
class CareItemMenu extends StatelessWidget {
  const CareItemMenu({
    super.key,
    required this.entry,
    required this.isClosed,
    required this.onEdit,
    required this.onPause,
    required this.onResume,
    required this.onArchive,
    required this.onRestore,
  });

  final HealthEntry entry;
  final bool isClosed;
  final VoidCallback onEdit;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onArchive;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return PopupMenuButton<CareItemMenuAction>(
      key: const Key('care_item_menu'),
      tooltip: l.careItemMenuTooltip,
      onSelected: (action) {
        switch (action) {
          case CareItemMenuAction.edit:
            onEdit();
          case CareItemMenuAction.pause:
            onPause();
          case CareItemMenuAction.resume:
            onResume();
          case CareItemMenuAction.archive:
            onArchive();
          case CareItemMenuAction.restore:
            onRestore();
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<CareItemMenuAction>>[
          PopupMenuItem(
            value: CareItemMenuAction.edit,
            child: Text(l.edit),
          ),
        ];
        if (!isClosed && !entry.isPaused && entry.status == 'active') {
          items.add(
            PopupMenuItem(
              value: CareItemMenuAction.pause,
              child: Text(l.careItemMenuPause),
            ),
          );
        }
        if (entry.isPaused) {
          items.add(
            PopupMenuItem(
              value: CareItemMenuAction.resume,
              child: Text(l.careItemMenuResume),
            ),
          );
        }
        if (!isClosed) {
          items.add(
            PopupMenuItem(
              value: CareItemMenuAction.archive,
              child: Text(l.careItemMenuArchive),
            ),
          );
        } else {
          items.add(
            PopupMenuItem(
              value: CareItemMenuAction.restore,
              child: Text(l.careItemMenuRestore),
            ),
          );
        }
        return items;
      },
    );
  }
}

enum CareItemMenuAction { edit, pause, resume, archive, restore }
