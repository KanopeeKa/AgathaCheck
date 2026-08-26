import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/org_person.dart';
import '../../../domain/services/admin_contacts.dart';
import '../../providers/organization_providers.dart';
import '../org_person_tile.dart';
import '../org_person_tile_grid.dart';

class AdminContactsList extends ConsumerWidget {
  const AdminContactsList({
    super.key,
    required this.orgId,
    required this.people,
    required this.viewerUserId,
  });

  final String orgId;
  final List<OrgPersonSummary> people;
  final String? viewerUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final viewerRole = ref.watch(orgViewerRoleProvider(orgId));
    final canEditOthers = canEditOtherAdminContact(viewerRole, orgId);
    final sorted = sortAdminContacts(
      contacts: people,
      viewerUserId: viewerUserId,
    );

    if (sorted.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            l.adminContactsEmpty,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.adminContactsDescription,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        OrgPersonTileGrid(
          gridKey: const Key('admin_contacts_tile_grid'),
          tiles: sorted.map((person) {
            final isSelf = viewerHasAdminSelfCard(person, viewerUserId);
            return OrgPersonTile(
              key: Key('admin_contact_tile_${person.recordId}'),
              recordId: person.recordId,
              displayName: person.displayName,
              initials: person.initials,
              photoUrl: person.photoUrl,
              role: person.role,
              isPending: person.isPending,
              isSelf: isSelf,
              onTap: person.isPending
                  ? null
                  : () => context.push(person.detailPath(orgId)),
              trailing: !isSelf && canEditOthers
                  ? _AdminContactMenu(
                      person: person,
                      orgId: orgId,
                      onEdit: () => context.push(person.detailPath(orgId)),
                      onDelete: () => _confirmRemove(context, ref, person),
                    )
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    OrgPersonSummary person,
  ) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.orgRemoveMember),
        content: Text(l.adminContactsRemoveConfirm(person.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.orgRemoveMember),
          ),
        ],
      ),
    );
    if (confirmed != true || person.userId == null) return;

    await ref
        .read(orgMembersProvider(orgId).notifier)
        .removeMember(person.userId!);
    ref.invalidate(orgPeopleProvider(orgId));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.adminContactsRemoved(person.displayName))),
      );
    }
  }
}

class _AdminContactMenu extends StatelessWidget {
  const _AdminContactMenu({
    required this.person,
    required this.orgId,
    required this.onEdit,
    required this.onDelete,
  });

  final OrgPersonSummary person;
  final String orgId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface.withAlpha(230),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: PopupMenuButton<String>(
        key: Key('admin_contact_menu_${person.recordId}'),
        tooltip: l.adminContactsMoreOptions,
        icon: const Icon(Icons.more_vert, size: 20),
        padding: EdgeInsets.zero,
        onSelected: (action) {
          switch (action) {
            case 'edit':
              onEdit();
              break;
            case 'delete':
              onDelete();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'edit', child: Text(l.edit)),
          PopupMenuItem(
            value: 'delete',
            child: Text(
              l.orgRemoveMember,
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
