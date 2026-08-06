import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// App-bar bulk actions menu for the People screen (v4 Phase D).
class OrgPeopleBulkActionsMenu extends StatelessWidget {
  const OrgPeopleBulkActionsMenu({
    super.key,
    required this.selectedCount,
    required this.onChangeRole,
  });

  final int selectedCount;
  final VoidCallback onChangeRole;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      key: const Key('org_people_bulk_actions'),
      tooltip: l.orgPeopleBulkActions,
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        switch (action) {
          case 'change_role':
            onChangeRole();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          key: const Key('org_people_bulk_change_role'),
          value: 'change_role',
          enabled: selectedCount > 0,
          child: Text(l.orgPeopleBulkChangeRole),
        ),
        PopupMenuItem(
          key: const Key('org_people_bulk_onboard_foster'),
          value: 'onboard_foster',
          enabled: false,
          child: Tooltip(
            message: l.orgPeopleBulkOnboardFosterComingSoon,
            child: Text(
              l.orgPeopleBulkOnboardFoster,
              style: TextStyle(color: colorScheme.onSurface.withAlpha(140)),
            ),
          ),
        ),
      ],
    );
  }
}
