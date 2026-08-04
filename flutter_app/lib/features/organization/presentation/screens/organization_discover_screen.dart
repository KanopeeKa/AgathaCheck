import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/org_discovery_provider.dart';
import '../utils/org_discover_entry_context.dart';
import '../widgets/org_discovery/org_discover_browse_as_banner.dart';
import '../widgets/org_discovery/org_discover_search_field.dart';
import '../widgets/org_discovery/org_discovery_list.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';

/// Dedicated discover screen — search, browse-as banner, return context (D-v3-DISC).
class OrganizationDiscoverScreen extends ConsumerWidget {
  const OrganizationDiscoverScreen({
    super.key,
    this.from = OrgDiscoverEntryContext.dashboard,
    this.orgId,
  });

  final OrgDiscoverEntryContext from;
  final String? orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final returnPath = orgDiscoverReturnPath(from: from, orgId: orgId);

    return OrgShellScaffold(
      title: l.discoverOrganizations,
      navVariant: OrgNavTitleVariant.textOnly,
      leadingKey: const Key('org_discover_back'),
      backPath: returnPath,
      onBack: () => _handleBack(context, returnPath),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(orgDiscoveryListProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OrgDiscoverBrowseAsBanner(from: from, orgId: orgId),
            const OrgDiscoverSearchField(),
            const SizedBox(height: 12),
            OrgDiscoveryList(emptyMessageForSearch: l.orgDiscoverySearchEmpty),
          ],
        ),
      ),
    );
  }

  void _handleBack(BuildContext context, String returnPath) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(returnPath);
  }
}
