import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization_member.dart';
import '../providers/organization_providers.dart';
import '../widgets/organization_invite_by_email_dialog.dart';
import '../widgets/organization_role_labels.dart';

class OrganizationMembersScreen extends ConsumerWidget {
  const OrganizationMembersScreen({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(orgMembersProvider(orgId));
    final isSuperAdmin = ref.watch(isOrgSuperUserProvider(orgId));
    final isOrgAdmin = ref.watch(isOrgAdminProvider(orgId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(title: l.orgMembers),
        leading: IconButton(
          key: const Key('org_members_back'),
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.pop(),
        ),
        actions: [
          if (isOrgAdmin)
            IconButton(
              key: const Key('org_generate_invite'),
              icon: const Icon(Icons.person_add),
              tooltip: l.orgInviteMember,
              onPressed: () => showOrganizationInviteByEmailDialog(
                context: context,
                ref: ref,
                orgId: orgId,
              ),
            ),
        ],
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('$e'),
              const SizedBox(height: 8),
              ElevatedButton(
                key: const Key('org_members_retry'),
                onPressed: () => ref.invalidate(orgMembersProvider(orgId)),
                child: Text(l.retry),
              ),
            ],
          ),
        ),
        data: (members) {
          if (members.isEmpty) {
            return Center(child: Text(l.orgNoMembers));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return _MemberCard(
                member: member,
                orgId: orgId,
                isOrgAdmin: isOrgAdmin,
                isSuperAdmin: isSuperAdmin,
              );
            },
          );
        },
      ),
    );
  }
}

class _MemberCard extends ConsumerWidget {
  const _MemberCard({
    required this.member,
    required this.orgId,
    required this.isOrgAdmin,
    required this.isSuperAdmin,
  });

  final OrganizationMember member;
  final String orgId;
  final bool isOrgAdmin;
  final bool isSuperAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final isPending = member.role.isPending;
    final roleLabel = localizedOrgMemberRole(l, member.role);

    return MergeSemantics(
      child: Semantics(
        label: '${member.displayName}, $roleLabel',
        child: Opacity(
          opacity: isPending ? 0.7 : 1.0,
          child: Card(
            key: Key('org_member_card_${member.userId}'),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isPending
                    ? Colors.grey.shade300
                    : member.role.isSuperAdmin
                        ? Colors.amber.withAlpha(40)
                        : colorScheme.secondaryContainer,
                child: isPending
                    ? Icon(Icons.hourglass_empty,
                        size: 18, color: Colors.grey.shade600)
                    : Text(
                        member.initials,
                        style: TextStyle(
                          color: member.role.isSuperAdmin
                              ? Colors.amber[800]
                              : colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              title: Text(
                member.displayName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontStyle: isPending ? FontStyle.italic : null,
                  color: isPending ? colorScheme.onSurfaceVariant : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (member.email.isNotEmpty)
                    Text(
                      member.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPending
                          ? Colors.orange.withAlpha(30)
                          : member.role.isSuperAdmin
                              ? AppTheme.orgSuperUserBg
                              : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPending)
                          Icon(Icons.schedule,
                              size: 12, color: Colors.orange[800]),
                        if (member.role.isSuperAdmin && !isPending)
                          Icon(Icons.star, size: 12, color: Colors.amber[800]),
                        if (member.role.isSuperAdmin || isPending)
                          const SizedBox(width: 4),
                        Text(
                          roleLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isPending
                                ? Colors.orange[800]
                                : member.role.isSuperAdmin
                                    ? AppTheme.orgSuperUserFg
                                    : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              trailing: isOrgAdmin && !isPending
                  ? PopupMenuButton<String>(
                      key: Key('org_member_menu_${member.userId}'),
                      tooltip: l.orgChangeRole,
                      onSelected: (action) =>
                          _handleAction(context, ref, action),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'change_role',
                          child: ListTile(
                            leading: const Icon(Icons.swap_horiz),
                            title: Text(l.orgChangeRole),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: ListTile(
                            leading:
                                const Icon(Icons.person_remove, color: Colors.red),
                            title: Text(l.orgRemoveMember,
                                style: const TextStyle(color: Colors.red)),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) async {
    switch (action) {
      case 'change_role':
        await _showChangeRoleDialog(context, ref);
        break;
      case 'remove':
        _showRemoveDialog(context, ref);
        break;
    }
  }

  Future<void> _showChangeRoleDialog(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    final options = invitableRoleWires(isSuperAdmin: isSuperAdmin);
    String selectedRole = member.role.toWire();
    if (!options.contains(selectedRole)) {
      selectedRole = options.first;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.orgSelectNewRole),
          content: DropdownButtonFormField<String>(
            value: selectedRole,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: options
                .map((wire) => DropdownMenuItem(
                      value: wire,
                      child: Text(invitableRoleLabel(l, wire)),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => selectedRole = value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(orgMembersProvider(orgId).notifier)
                      .updateMemberRole(member.userId, selectedRole);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                }
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.orgRemoveMember),
        content: Text(l.orgRemoveMemberConfirm),
        actions: [
          TextButton(
            key: const Key('org_remove_member_cancel'),
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('org_remove_member_confirm'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(orgMembersProvider(orgId).notifier)
                    .removeMember(member.userId);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              }
            },
            child: Text(l.orgRemoveMember),
          ),
        ],
      ),
    );
  }
}
