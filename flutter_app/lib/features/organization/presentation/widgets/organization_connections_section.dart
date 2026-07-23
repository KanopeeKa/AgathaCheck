import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/org_connection.dart';
import '../providers/organization_providers.dart';

class OrganizationConnectionsSection extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<OrganizationConnectionsSection> createState() =>
      _OrganizationConnectionsSectionState();
}

class _OrganizationConnectionsSectionState
    extends ConsumerState<OrganizationConnectionsSection> {
  bool _expanded = false;

  Future<void> _createRequest() async {
    final controller = TextEditingController();
    final targetOrgId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.l.createConnectionRequest),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: widget.l.targetOrgId),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(widget.l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(widget.l.confirm),
          ),
        ],
      ),
    );
    if (targetOrgId == null || targetOrgId.isEmpty) return;

    try {
      final token = await ref
          .read(orgConnectionsProvider(widget.orgId).notifier)
          .createRequest(targetOrgId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(widget.l.connectionTokenCreated),
          content: SelectableText(token),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: token));
                Navigator.pop(ctx);
              },
              child: Text(widget.l.copy),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(widget.l.ok),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _disconnect(OrgConnection connection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.l.disconnectOrganisation),
        content: Text(
          widget.l.disconnectOrganisationConfirm(connection.peerOrgName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(widget.l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(widget.l.disconnectOrganisation),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(orgConnectionsProvider(widget.orgId).notifier)
        .disconnect(connection.peerOrgId);
  }

  @override
  Widget build(BuildContext context) {
    final connectionsAsync = ref.watch(orgConnectionsProvider(widget.orgId));
    final requestsAsync = ref.watch(
      orgConnectionRequestsProvider(widget.orgId),
    );

    return Card(
      color: widget.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              key: const Key('org_connections_header'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Icon(
                    Icons.hub_outlined,
                    size: 20,
                    color: widget.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.l.orgConnections,
                      style: widget.theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: widget.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              connectionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('$e'),
                data: (connections) {
                  if (connections.isEmpty) {
                    return Text(
                      widget.l.orgConnectionsEmpty,
                      style: widget.theme.textTheme.bodyMedium,
                    );
                  }
                  return Column(
                    children: connections
                        .map(
                          (c) => ListTile(
                            key: Key('org_connection_${c.peerOrgId}'),
                            title: Text(c.peerOrgName),
                            subtitle: c.peerOrgEmail?.isNotEmpty == true
                                ? Text(c.peerOrgEmail!)
                                : null,
                            trailing: IconButton(
                              tooltip: widget.l.disconnectOrganisation,
                              icon: const Icon(Icons.link_off),
                              onPressed: () => _disconnect(c),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 8),
              requestsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (requests) {
                  final pending = requests.where((r) => r.isPending).toList();
                  if (pending.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.l.connectionRequests,
                        style: widget.theme.textTheme.titleSmall,
                      ),
                      ...pending.map(
                        (r) => ListTile(
                          dense: true,
                          title: Text(r.targetOrgId),
                          subtitle: Text(r.expiresAt.toLocal().toString()),
                          trailing: IconButton(
                            tooltip: widget.l.revokeConnectionRequest,
                            icon: const Icon(Icons.cancel_outlined),
                            onPressed: () => ref
                                .read(
                                  orgConnectionRequestsProvider(
                                    widget.orgId,
                                  ).notifier,
                                )
                                .revoke(r.id),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('org_create_connection'),
                onPressed: _createRequest,
                icon: const Icon(Icons.add_link),
                label: Text(widget.l.createConnectionRequest),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
