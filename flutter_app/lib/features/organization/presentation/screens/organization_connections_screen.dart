import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';
import '../widgets/organization_connections_section.dart';

class OrganizationConnectionsScreen extends ConsumerWidget {
  const OrganizationConnectionsScreen({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return OrgShellScaffold(
      key: const Key('org_connections_screen'),
      title: l.orgConnections,
      orgId: orgId,
      navVariant: OrgNavTitleVariant.withOrgLogo,
      leadingKey: const Key('org_connections_back'),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OrganizationConnectionsSection(
            orgId: orgId,
            theme: theme,
            colorScheme: colorScheme,
            l: l,
          ),
        ],
      ),
    );
  }
}
