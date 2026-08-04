import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/org_discovery_provider.dart';
import '../widgets/org_discovery/org_discovery_list.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';

/// Dedicated discover screen — Phase 4 shell; Phase 5 adds search and browse-as.
class OrganizationDiscoverScreen extends ConsumerWidget {
  const OrganizationDiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    return OrgShellScaffold(
      title: l.discoverOrganizations,
      navVariant: OrgNavTitleVariant.textOnly,
      leadingKey: const Key('org_discover_back'),
      onBack: () => context.pop(),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(orgDiscoveryListProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [OrgDiscoveryList()],
        ),
      ),
    );
  }
}
