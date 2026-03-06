import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/organization_member.dart';
import '../providers/organization_providers.dart';

class OrganizationDetailScreen extends ConsumerWidget {
  const OrganizationDetailScreen({super.key, required this.orgId});

  final int orgId;

  String _localizedTypeLabel(AppLocalizations l, OrganizationType type) {
    switch (type) {
      case OrganizationType.professional:
        return l.orgTypeProfessional;
      case OrganizationType.charity:
        return l.orgTypeCharity;
    }
  }

  String _localizedRoleLabel(AppLocalizations l, String role) {
    return role == 'super_user' ? l.orgSuperUser : l.orgMember;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgsAsync = ref.watch(organizationListProvider);
    final membersAsync = ref.watch(orgMembersProvider(orgId));
    final isSuperUser = ref.watch(isOrgSuperUserProvider(orgId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return orgsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l.organizations)),
        body: Center(child: Text('$e')),
      ),
      data: (orgs) {
        final org = orgs.where((o) => o.id == orgId).firstOrNull;
        if (org == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l.organizations)),
            body: const Center(child: Text('Not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(org.name),
            leading: IconButton(
              key: const Key('org_detail_back'),
              icon: const Icon(Icons.arrow_back),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => context.go('/my-details'),
            ),
            actions: [
              if (isSuperUser)
                IconButton(
                  key: const Key('org_edit_button'),
                  icon: const Icon(Icons.edit),
                  tooltip: l.editOrganization,
                  onPressed: () => context.push('/organizations/$orgId/edit'),
                ),
              PopupMenuButton<String>(
                key: const Key('org_detail_menu'),
                tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                onSelected: (value) => _handleMenuAction(context, ref, value, org),
                itemBuilder: (context) => [
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
                  PopupMenuItem(
                    value: 'pets',
                    child: ListTile(
                      leading: const Icon(Icons.pets),
                      title: Text(l.orgPets),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'archived',
                    child: ListTile(
                      leading: const Icon(Icons.archive),
                      title: Text(l.orgArchived),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'leave',
                    child: ListTile(
                      leading: const Icon(Icons.exit_to_app, color: Colors.orange),
                      title: Text(l.orgLeave,
                          style: const TextStyle(color: Colors.orange)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (isSuperUser)
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: Text(l.deleteOrganization,
                            style: const TextStyle(color: Colors.red)),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInfoCard(org, theme, colorScheme, l),
              const SizedBox(height: 16),
              _buildContactCard(org, theme, colorScheme),
              const SizedBox(height: 16),
              _buildMembersSection(context, ref, membersAsync, theme, colorScheme, l),
              const SizedBox(height: 16),
              _buildPetsSection(context, org, theme, colorScheme, l),
              const SizedBox(height: 16),
              _buildArchivedSection(context, theme, colorScheme, l),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(Organization org, ThemeData theme, ColorScheme colorScheme, AppLocalizations l) {
    return MergeSemantics(
      child: Semantics(
        label: '${org.name}, ${_localizedTypeLabel(l, org.type)}',
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: org.type == OrganizationType.professional
                          ? colorScheme.primaryContainer
                          : colorScheme.tertiaryContainer,
                      child: Icon(
                        org.type == OrganizationType.professional
                            ? Icons.business
                            : Icons.volunteer_activism,
                        size: 32,
                        color: org.type == OrganizationType.professional
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onTertiaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            org.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: org.type == OrganizationType.professional
                                  ? colorScheme.primaryContainer
                                  : colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _localizedTypeLabel(l, org.type),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: org.type == OrganizationType.professional
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (org.bio.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(org.bio, style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  )),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.people,
                      label: l.memberCount(org.memberCount),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      icon: Icons.pets,
                      label: l.petCount(org.petCount),
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(Organization org, ThemeData theme, ColorScheme colorScheme) {
    final hasContact = org.email.isNotEmpty ||
        org.phone.isNotEmpty ||
        org.address.isNotEmpty ||
        org.website.isNotEmpty;

    if (!hasContact) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (org.email.isNotEmpty)
              _ContactRow(icon: Icons.email, text: org.email, colorScheme: colorScheme),
            if (org.phone.isNotEmpty)
              _ContactRow(icon: Icons.phone, text: org.phone, colorScheme: colorScheme),
            if (org.address.isNotEmpty)
              _ContactRow(icon: Icons.location_on, text: org.address, colorScheme: colorScheme),
            if (org.website.isNotEmpty)
              _ContactRow(icon: Icons.language, text: org.website, colorScheme: colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context, WidgetRef ref,
      AsyncValue membersAsync, ThemeData theme, ColorScheme colorScheme, AppLocalizations l) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.orgMembers,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold)),
                TextButton(
                  key: const Key('org_view_all_members'),
                  onPressed: () => context.push('/organizations/$orgId/members'),
                  child: const Text('>'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            membersAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text('$e',
                  style: TextStyle(color: colorScheme.error)),
              data: (members) {
                final displayMembers = members.take(3).toList();
                return Column(
                  children: [
                    ...displayMembers.map((member) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.secondaryContainer,
                        child: Text(
                          member.initials,
                          style: TextStyle(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(member.displayName),
                      subtitle: Text(member.email),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: member.role == OrgMemberRole.superUser
                              ? Colors.amber.withAlpha(30)
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _localizedRoleLabel(l, member.role == OrgMemberRole.superUser ? 'super_user' : 'member'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: member.role == OrgMemberRole.superUser
                                ? Colors.amber[800]
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      dense: true,
                    )),
                    if (members.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+ ${members.length - 3}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetsSection(BuildContext context, Organization org,
      ThemeData theme, ColorScheme colorScheme, AppLocalizations l) {
    return Semantics(
      label: l.petCount(org.petCount),
      child: Card(
        child: ListTile(
          key: const Key('org_view_pets'),
          leading: Icon(Icons.pets, color: colorScheme.primary),
          title: Text(l.orgPets),
          subtitle: Text(l.petCount(org.petCount)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/organizations/$orgId/pets'),
        ),
      ),
    );
  }

  Widget _buildArchivedSection(BuildContext context,
      ThemeData theme, ColorScheme colorScheme, AppLocalizations l) {
    return Semantics(
      label: l.orgArchived,
      child: Card(
        child: ListTile(
          key: const Key('org_view_archived'),
          leading: Icon(Icons.archive, color: colorScheme.onSurfaceVariant),
          title: Text(l.orgArchived),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/organizations/$orgId/archived'),
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref,
      String action, Organization org) async {
    switch (action) {
      case 'invite':
        _showInviteDialog(context, ref);
        break;
      case 'members':
        context.push('/organizations/$orgId/members');
        break;
      case 'pets':
        context.push('/organizations/$orgId/pets');
        break;
      case 'archived':
        context.push('/organizations/$orgId/archived');
        break;
      case 'leave':
        _showLeaveDialog(context, ref);
        break;
      case 'delete':
        _showDeleteDialog(context, ref, org);
        break;
    }
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    try {
      final inviteCode = await ref
          .read(orgMembersProvider(orgId).notifier)
          .createInvite();
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.orgInviteMember),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(inviteCode),
                const SizedBox(height: 8),
                Text(l.orgInviteExpiry, style: Theme.of(ctx).textTheme.bodySmall),
              ],
            ),
            actions: [
              TextButton(
                key: const Key('org_invite_close'),
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.close),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  void _showLeaveDialog(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    showDialog(
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
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(orgMembersProvider(orgId).notifier)
                    .leaveOrganization();
                ref.invalidate(organizationListProvider);
                if (context.mounted) {
                  context.go('/my-details');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              }
            },
            child: Text(l.orgLeave),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref,
      Organization org) {
    final l = AppLocalizations.of(context)!;
    showDialog(
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
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(organizationListProvider.notifier)
                    .deleteOrganization(orgId);
                if (context.mounted) {
                  context.go('/my-details');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              }
            },
            child: Text(l.deleteOrganization),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.text,
    required this.colorScheme,
  });

  final IconData icon;
  final String text;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
