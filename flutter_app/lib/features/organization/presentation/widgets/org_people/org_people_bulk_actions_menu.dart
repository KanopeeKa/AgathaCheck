import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

class OrgPeopleBulkActionsMenu extends StatelessWidget {
  const OrgPeopleBulkActionsMenu({
    super.key,
    required this.selectedCount,
    required this.onChangeRole,
    required this.onOnboardFoster,
    this.canOnboardFoster = false,
  });

  final int selectedCount;
  final VoidCallback onChangeRole;
  final VoidCallback onOnboardFoster;
  final bool canOnboardFoster;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return PopupMenuButton<String>(
      key: const Key('org_people_bulk_actions'),
      tooltip: l.orgPeopleBulkActions,
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        switch (action) {
          case 'change_role':
            onChangeRole();
            break;
          case 'onboard_foster':
            onOnboardFoster();
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
          enabled: selectedCount > 0 && canOnboardFoster,
          child: Text(l.orgPeopleBulkOnboardFoster),
        ),
      ],
    );
  }
}
