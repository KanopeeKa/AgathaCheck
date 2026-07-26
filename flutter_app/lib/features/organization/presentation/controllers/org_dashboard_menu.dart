import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/experience_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization.dart';
import '../../domain/services/org_permissions.dart';
import '../providers/admin_contact_providers.dart';
import '../providers/organization_providers.dart';
import '../widgets/organization_invite_by_email_dialog.dart';

Future<void> handleOrgDashboardMenuAction({
  required BuildContext context,
  required WidgetRef ref,
  required String orgId,
  required String action,
  required Organization org,
}) async {
  switch (action) {
    case 'invite':
      showOrganizationInviteByEmailDialog(
        context: context,
        ref: ref,
        orgId: orgId,
      );
      break;
    case 'members':
      context.push('/o/orgs/$orgId/members');
      break;
    case 'leave':
      await _showLeaveDialog(context, ref, orgId);
      break;
    case 'delete':
      await _showDeleteDialog(context, ref, orgId, org);
      break;
  }
}

List<PopupMenuEntry<String>> buildOrgDashboardMenuItems({
  required BuildContext context,
  required WidgetRef ref,
  required String orgId,
}) {
  final l = AppLocalizations.of(context)!;
  final xp = context.experienceColors;
  final colorScheme = Theme.of(context).colorScheme;
  final role = ref.watch(orgViewerRoleProvider(orgId));
  final canManageMembers = role != null &&
      hasPermission(role, orgId, 'manage_members');
  final canManagePermissions = role != null &&
      hasPermission(role, orgId, 'manage_permissions');

  return [
    if (canManageMembers) ...[
      PopupMenuItem(
        value: 'invite',
        child: ListTile(
          leading: const Icon(Icons.person_add),
          title: Text(l.orgInviteMember),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      PopupMenuItem(
        value: 'members',
        child: ListTile(
          leading: const Icon(Icons.people),
          title: Text(l.orgMembers),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      const PopupMenuDivider(),
    ],
    PopupMenuItem(
      value: 'leave',
      child: ListTile(
        leading: Icon(Icons.exit_to_app, color: xp.warning),
        title: Text(l.orgLeave, style: TextStyle(color: xp.warning)),
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
    ),
    if (canManagePermissions)
      PopupMenuItem(
        value: 'delete',
        child: ListTile(
          leading: Icon(Icons.delete, color: colorScheme.error),
          title: Text(
            l.deleteOrganization,
            style: TextStyle(color: colorScheme.error),
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
  ];
}

Future<void> _showLeaveDialog(
  BuildContext context,
  WidgetRef ref,
  String orgId,
) async {
  final l = AppLocalizations.of(context)!;
  final xp = context.experienceColors;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.orgLeave),
      content: Text(l.orgLeaveConfirm),
      actions: [
        TextButton(
          key: const Key('org_leave_cancel'),
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('org_leave_confirm'),
          style: FilledButton.styleFrom(backgroundColor: xp.warning),
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await ref
                  .read(orgMembersProvider(orgId).notifier)
                  .leaveOrganization();
              ref.invalidate(organizationListProvider);
              if (context.mounted) {
                context.go('/o/orgs');
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('$e')));
              }
            }
          },
          child: Text(l.orgLeave),
        ),
      ],
    ),
  );
}

Future<void> _showDeleteDialog(
  BuildContext context,
  WidgetRef ref,
  String orgId,
  Organization org,
) async {
  final l = AppLocalizations.of(context)!;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.deleteOrganization),
      content: Text(l.orgDeleteConfirm),
      actions: [
        TextButton(
          key: const Key('org_delete_cancel'),
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('org_delete_confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await ref
                  .read(organizationListProvider.notifier)
                  .deleteOrganization(orgId);
              if (context.mounted) {
                context.go('/o/orgs');
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('$e')));
              }
            }
          },
          child: Text(l.deleteOrganization),
        ),
      ],
    ),
  );
}
