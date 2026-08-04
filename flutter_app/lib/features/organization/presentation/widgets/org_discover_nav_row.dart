import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';

/// Dashboard entry row for the dedicated Discover screen (D-v3-IA-2).
class OrgDiscoverNavRow extends StatelessWidget {
  const OrgDiscoverNavRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Semantics(
      identifier: 'org_discover_nav_row',
      button: true,
      label: l.discoverOrganizations,
      child: Card(
        color: theme.cardTheme.color,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: theme.cardTheme.shape,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          key: const Key('org_discover_nav_row'),
          title: Text(
            l.discoverOrganizations,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onTap: () => context.push('/o/orgs/discover?from=dashboard'),
        ),
      ),
    );
  }
}
