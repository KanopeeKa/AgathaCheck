import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/admin_contact_self_prefs.dart';
import '../../../domain/entities/org_person.dart';
import '../../../domain/services/admin_contacts.dart';
import '../../providers/admin_contact_providers.dart';
import '../../providers/organization_providers.dart';
import 'admin_contact_card.dart';
import 'admin_contact_invite_dialog.dart';

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
    final selfPrefs = ref.watch(adminContactSelfPrefsProvider(orgId));
    final canManage = canManageAdminContacts(viewerRole, orgId);
    final canEditOthers = canEditOtherAdminContact(viewerRole, orgId);
    final sorted = sortAdminContacts(
      contacts: people,
      viewerUserId: viewerUserId,
    );

    if (sorted.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
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
          ),
          if (canManage)
            OutlinedButton.icon(
              key: const Key('admin_contacts_add_button'),
              onPressed: () => showAdminContactInviteDialog(
                context: context,
                ref: ref,
                orgId: orgId,
              ),
              icon: const Icon(Icons.person_add, size: 18),
              label: Text(l.adminContactsAddAdmin),
            ),
        ],
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
        ...sorted.map((person) {
          final isSelf = viewerHasAdminSelfCard(person, viewerUserId);
          return AdminContactCard(
            key: Key('admin_contact_card_${person.recordId}'),
            person: person,
            orgId: orgId,
            viewerRole: viewerRole,
            viewerUserId: viewerUserId,
            phoneVisibility: isSelf
                ? selfPrefs.phoneVisibility
                : AdminPhoneVisibility.admins,
            isSelf: isSelf,
            canEditOther: !isSelf && canEditOthers,
            canDeleteOther: !isSelf && canEditOthers,
            onView: person.isPending
                ? null
                : () => context.push(person.detailPath(orgId)),
            onEdit: () => context.push(person.detailPath(orgId)),
            onDelete: () => _confirmRemove(context, ref, person),
          );
        }),
        if (canManage) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('admin_contacts_add_button'),
            onPressed: () => showAdminContactInviteDialog(
              context: context,
              ref: ref,
              orgId: orgId,
            ),
            icon: const Icon(Icons.person_add, size: 18),
            label: Text(l.adminContactsAddAdmin),
          ),
        ],
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
