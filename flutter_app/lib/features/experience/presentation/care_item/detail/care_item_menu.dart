import 'package:flutter/material.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';

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
    this.onPlanAnotherDate,
  });

  final HealthEntry entry;
  final bool isClosed;
  final VoidCallback onEdit;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final VoidCallback? onPlanAnotherDate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Semantics(
      identifier: 'care_item_menu',
      child: PopupMenuButton<CareItemMenuAction>(
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
            case CareItemMenuAction.planAnotherDate:
              onPlanAnotherDate?.call();
          }
        },
        itemBuilder: (context) {
          final items = <PopupMenuEntry<CareItemMenuAction>>[
            PopupMenuItem(value: CareItemMenuAction.edit, child: Text(l.edit)),
          ];
          if (onPlanAnotherDate != null && !isClosed && !entry.isPaused) {
            items.add(
              PopupMenuItem(
                value: CareItemMenuAction.planAnotherDate,
                child: Text(l.carePlanAnotherDate),
              ),
            );
          }
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
      ),
    );
  }
}

enum CareItemMenuAction {
  edit,
  pause,
  resume,
  archive,
  restore,
  planAnotherDate,
}
