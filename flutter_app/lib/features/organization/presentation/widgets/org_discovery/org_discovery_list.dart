import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../providers/org_discovery_provider.dart';
import 'org_discovery_skeleton_list.dart';
import 'org_discovery_tile.dart';

class OrgDiscoveryList extends ConsumerWidget {
  const OrgDiscoveryList({super.key, this.emptyMessageForSearch});

  final String? emptyMessageForSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveryAsync = ref.watch(orgDiscoveryListProvider);
    final searchQuery = ref.watch(orgDiscoverySearchQueryProvider);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return discoveryAsync.when(
      loading: () => const OrgDiscoverySkeletonList(),
      error: (error, _) => Column(
        key: const Key('org_discovery_error'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(height: 8),
          Text(
            l.orgDiscoveryLoadError,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('org_discovery_retry_button'),
            onPressed: () => ref.invalidate(orgDiscoveryListProvider),
            child: Text(l.retry),
          ),
        ],
      ),
      data: (organizations) {
        if (organizations.isEmpty) {
          final emptyMessage = searchQuery.trim().isNotEmpty
              ? (emptyMessageForSearch ?? l.orgDiscoverySearchEmpty)
              : l.orgDiscoveryEmpty;
          final emptyKey = searchQuery.trim().isNotEmpty
              ? const Key('org_discovery_search_empty')
              : const Key('org_discovery_empty');
          return Semantics(
            key: emptyKey,
            label: emptyMessage,
            child: Text(
              emptyMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return Column(
          key: const Key('org_discovery_results'),
          children: [
            for (final org in organizations)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OrgDiscoveryTile(organization: org),
              ),
          ],
        );
      },
    );
  }
}
