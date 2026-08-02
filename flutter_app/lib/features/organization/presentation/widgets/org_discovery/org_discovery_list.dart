import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../providers/org_discovery_provider.dart';
import 'org_discovery_skeleton_list.dart';
import 'org_discovery_tile.dart';

class OrgDiscoveryList extends ConsumerWidget {
  const OrgDiscoveryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveryAsync = ref.watch(orgDiscoveryListProvider);
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
          return Semantics(
            key: const Key('org_discovery_empty'),
            label: l.orgDiscoveryEmpty,
            child: Text(
              l.orgDiscoveryEmpty,
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
