import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/org_connection.dart';
import '../../providers/organization_providers.dart';

/// Profile preview of connected organisation tiles.
class OrganisationProfileConnections extends ConsumerWidget {
  const OrganisationProfileConnections({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(orgConnectionsProvider(orgId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    final l = AppLocalizations.of(context)!;

    return connectionsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Text('$e', style: mutedStyle),
      data: (connections) {
        if (connections.isEmpty) {
          return Text(l.orgConnectionsEmpty, style: mutedStyle);
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: connections
              .map((connection) => _ConnectionTile(connection: connection))
              .toList(),
        );
      },
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile({required this.connection});

  final OrgConnection connection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      container: true,
      label: connection.peerOrgName,
      child: Material(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withAlpha(120),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.hub_outlined, size: 20, color: colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                connection.peerOrgName,
                key: Key('org_profile_connection_${connection.peerOrgId}'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (connection.peerOrgEmail?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  connection.peerOrgEmail!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
