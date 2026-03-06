import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/presentation/widgets/pet_card.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/organization_member.dart';
import '../providers/organization_providers.dart';

class OrganizationDetailScreen extends ConsumerStatefulWidget {
  const OrganizationDetailScreen({super.key, required this.orgId});

  final int orgId;

  @override
  ConsumerState<OrganizationDetailScreen> createState() =>
      _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState
    extends ConsumerState<OrganizationDetailScreen> {
  bool _petsExpanded = true;

  int get orgId => widget.orgId;

  String _localizedTypeLabel(AppLocalizations l, OrganizationType type) {
    switch (type) {
      case OrganizationType.professional:
        return l.orgTypeProfessional;
      case OrganizationType.charity:
        return l.orgTypeCharity;
    }
  }

  String _localizedRoleLabel(AppLocalizations l, OrgMemberRole role) {
    switch (role) {
      case OrgMemberRole.superUser:
        return l.orgSuperUser;
      case OrgMemberRole.pendingMember:
      case OrgMemberRole.pendingSuperUser:
        return l.invited;
      case OrgMemberRole.member:
        return l.orgMember;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgsAsync = ref.watch(organizationListProvider);
    final membersAsync = ref.watch(orgMembersProvider(orgId));
    final petsAsync = ref.watch(orgPetsProvider(orgId));
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
          backgroundColor: AppTheme.orgBlue,
          appBar: AppBar(
            backgroundColor: AppTheme.orgBlue,
            title: Text(org.name),
            leading: IconButton(
              key: const Key('org_detail_back'),
              icon: const Icon(Icons.arrow_back),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => context.go('/organizations'),
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
              _buildMembersSection(context, ref, membersAsync, isSuperUser, theme, colorScheme, l),
              const SizedBox(height: 16),
              _buildPetsSection(context, ref, petsAsync, isSuperUser, theme, colorScheme, l),
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
          color: AppTheme.orgBlueDarker,
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
                          ? AppTheme.orgIconBg
                          : AppTheme.orgCharityBg,
                      child: Icon(
                        org.type == OrganizationType.professional
                            ? Icons.business
                            : Icons.volunteer_activism,
                        size: 32,
                        color: org.type == OrganizationType.professional
                            ? AppTheme.orgIconFg
                            : AppTheme.orgCharityFg,
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
                                  ? AppTheme.orgBadgeBg
                                  : AppTheme.orgCharityBadgeBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _localizedTypeLabel(l, org.type),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: org.type == OrganizationType.professional
                                    ? AppTheme.orgBadgeFg
                                    : AppTheme.orgCharityBadgeFg,
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
      color: AppTheme.orgBlueDarker,
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
      AsyncValue membersAsync, bool isSuperUser, ThemeData theme, ColorScheme colorScheme, AppLocalizations l) {
    return Card(
      color: AppTheme.orgBlueDarker,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.people,
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold)),
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
                return Column(
                  children: [
                    ...members.map((member) {
                      final isPending = member.role.isPending;
                      return Opacity(
                        opacity: isPending ? 0.7 : 1.0,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPending
                                ? Colors.grey.shade300
                                : AppTheme.orgIconBg,
                            child: isPending
                                ? Icon(Icons.hourglass_empty, size: 18, color: Colors.grey.shade600)
                                : Text(
                                    member.initials,
                                    style: const TextStyle(
                                      color: AppTheme.orgIconFg,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          title: Text(
                            member.displayName,
                            style: isPending
                                ? TextStyle(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant)
                                : null,
                          ),
                          subtitle: Text(member.email),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPending
                                  ? Colors.orange.withAlpha(30)
                                  : member.role == OrgMemberRole.superUser
                                      ? AppTheme.orgSuperUserBg
                                      : AppTheme.orgChipBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _localizedRoleLabel(l, member.role),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isPending
                                    ? Colors.orange.shade800
                                    : member.role == OrgMemberRole.superUser
                                        ? AppTheme.orgSuperUserFg
                                        : AppTheme.orgChipFg,
                              ),
                            ),
                          ),
                          dense: true,
                        ),
                      );
                    }),
                    if (isSuperUser) ...[
                      const Divider(),
                      OutlinedButton.icon(
                        key: const Key('org_add_user_button'),
                        onPressed: () => _showInviteByEmailDialog(context, ref, l),
                        icon: const Icon(Icons.person_add, size: 18),
                        label: Text(l.addUser),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetsSection(BuildContext context, WidgetRef ref,
      AsyncValue petsAsync, bool isSuperUser,
      ThemeData theme, ColorScheme colorScheme, AppLocalizations l) {
    return Card(
      color: AppTheme.orgBlueDarker,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              key: const Key('org_pets_header'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _petsExpanded = !_petsExpanded),
              child: Row(
                children: [
                  Icon(Icons.pets, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l.orgPets,
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold)),
                  ),
                  AnimatedRotation(
                    turns: _petsExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more,
                        color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (_petsExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: petsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Column(
                    children: [
                      Text('$e', style: TextStyle(color: colorScheme.error)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(orgPetsProvider(orgId)),
                        child: Text(l.retry),
                      ),
                    ],
                  ),
                  data: (pets) {
                    if (pets.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.pets, size: 40,
                                  color: colorScheme.outline),
                              const SizedBox(height: 8),
                              Text(l.orgNoPets,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant)),
                              if (isSuperUser) ...[
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  key: const Key('org_add_pet_empty'),
                                  onPressed: () =>
                                      context.push('/add?orgId=$orgId'),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: Text(l.orgAddPet),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        ...pets.map((pet) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PetCard(
                            pet: pet,
                            onTap: () => context.push('/pet/${pet.id}'),
                          ),
                        )),
                        if (isSuperUser) ...[
                          const Divider(),
                          OutlinedButton.icon(
                            key: const Key('org_add_pet_button'),
                            onPressed: () =>
                                context.push('/add?orgId=$orgId'),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l.orgAddPet),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedSection(BuildContext context,
      ThemeData theme, ColorScheme colorScheme, AppLocalizations l) {
    return Semantics(
      label: l.orgArchived,
      child: Card(
        color: AppTheme.orgBlueDarker,
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

  void _showInviteByEmailDialog(BuildContext context, WidgetRef ref, AppLocalizations l) {
    final emailController = TextEditingController();
    String selectedRole = 'member';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.addUser),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.enterEmail, style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(l.selectRole, style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'member',
                    label: Text(l.orgMember),
                    icon: const Icon(Icons.person),
                  ),
                  ButtonSegment(
                    value: 'super_user',
                    label: Text(l.orgSuperUser),
                    icon: const Icon(Icons.admin_panel_settings),
                  ),
                ],
                selected: {selectedRole},
                onSelectionChanged: (v) => setState(() => selectedRole = v.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(orgMembersProvider(orgId).notifier)
                      .inviteByEmail(email, selectedRole);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.inviteSent)),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    final errorMsg = e.toString();
                    String displayMsg = errorMsg;
                    if (errorMsg.contains('user_not_found')) {
                      displayMsg = l.userNotFound;
                    } else if (errorMsg.contains('already_member')) {
                      displayMsg = l.alreadyMember;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(displayMsg)),
                    );
                  }
                }
              },
              child: Text(l.sendInvite),
            ),
          ],
        ),
      ),
    );
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
                  context.go('/organizations');
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
                  context.go('/organizations');
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
        color: AppTheme.orgChipBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.orgChipFg),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.orgChipFg,
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
