import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../providers/organization_providers.dart';
import '../../utils/org_discover_entry_context.dart';

/// Centered browse-as banner for the Discover screen (D-v3-DISC-2).
class OrgDiscoverBrowseAsBanner extends ConsumerWidget {
  const OrgDiscoverBrowseAsBanner({
    super.key,
    required this.from,
    this.orgId,
  });

  final OrgDiscoverEntryContext from;
  final String? orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final browseAsName = _resolveBrowseAsName(ref, l);

    return Semantics(
      identifier: 'org_discover_browse_as_banner',
      label: l.orgDiscoverBrowsingAs(browseAsName),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Center(
          child: Text(
            l.orgDiscoverBrowsingAs(browseAsName),
            key: const Key('org_discover_browse_as_banner'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  String _resolveBrowseAsName(WidgetRef ref, AppLocalizations l) {
    if (from == OrgDiscoverEntryContext.org) {
      final id = orgId?.trim() ?? '';
      if (id.isEmpty) return l.orgDiscoverBrowsingAsFallback;
      final orgs = ref.watch(organizationListProvider);
      return orgs.maybeWhen(
        data: (items) {
          final match = items.where((org) => org.id == id).firstOrNull;
          return match?.name.trim().isNotEmpty == true
              ? match!.name
              : l.orgDiscoverBrowsingAsFallback;
        },
        orElse: () => l.orgDiscoverBrowsingAsFallback,
      );
    }

    final user = ref.watch(authProvider).user;
    if (user == null) return l.orgDiscoverBrowsingAsFallback;
    final name = user.displayName.trim();
    return name.isNotEmpty ? name : l.orgDiscoverBrowsingAsFallback;
  }
}
