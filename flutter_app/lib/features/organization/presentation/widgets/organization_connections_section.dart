import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/org_connection.dart';
import '../providers/organization_providers.dart';

class OrganizationConnectionsSection extends ConsumerWidget {
  const OrganizationConnectionsSection({
    super.key,
    required this.orgId,
    required this.theme,
    required this.colorScheme,
    required this.l,
  });

  final String orgId;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final AppLocalizations l;

  Future<void> _disconnect(
    BuildContext context,
    WidgetRef ref,
    OrgConnection connection,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.disconnectOrganisation),
        content: Text(
          l.disconnectOrganisationConfirm(connection.peerOrgName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.disconnectOrganisation),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(orgConnectionsProvider(orgId).notifier)
        .disconnect(connection.peerOrgId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(orgConnectionsProvider(orgId));
    final requestsAsync = ref.watch(orgConnectionRequestsProvider(orgId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        connectionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
          data: (connections) {
            if (connections.isEmpty) {
              return Text(
                l.orgConnectionsEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              );
            }
            return Column(
              children: connections
                  .map(
                    (c) => ListTile(
                      key: Key('org_connection_${c.peerOrgId}'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.peerOrgName),
                      subtitle: c.peerOrgEmail?.isNotEmpty == true
                          ? Text(c.peerOrgEmail!)
                          : null,
                      trailing: IconButton(
                        tooltip: l.disconnectOrganisation,
                        icon: const Icon(Icons.link_off),
                        onPressed: () => _disconnect(context, ref, c),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        requestsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (requests) {
            final pending = requests.where((r) => r.isPending).toList();
            if (pending.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  l.connectionRequests,
                  style: theme.textTheme.titleSmall,
                ),
                ...pending.map(
                  (r) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(r.targetOrgId),
                    subtitle: Text(r.expiresAt.toLocal().toString()),
                    trailing: IconButton(
                      tooltip: l.revokeConnectionRequest,
                      icon: const Icon(Icons.cancel_outlined),
                      onPressed: () => ref
                          .read(
                            orgConnectionRequestsProvider(orgId).notifier,
                          )
                          .revoke(r.id),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Semantics(
          identifier: 'org_connections_discover_cta',
          button: true,
          label: l.discoverOrganizations,
          child: OutlinedButton.icon(
            key: const Key('org_connections_discover'),
            onPressed: () =>
                context.push('/o/orgs/discover?from=org&orgId=$orgId'),
            icon: const Icon(Icons.explore_outlined),
            label: Text(l.discoverOrganizations),
          ),
        ),
      ],
    );
  }
}
