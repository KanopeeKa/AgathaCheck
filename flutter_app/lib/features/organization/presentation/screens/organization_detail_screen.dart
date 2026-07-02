import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../sharing/presentation/providers/sharing_providers.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/organization_member.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../providers/organization_providers.dart';
import '../widgets/organization_archived_section.dart';
import '../widgets/organization_contact_card.dart';
import '../widgets/organization_hidden_shared_pets_section.dart';
import '../widgets/organization_info_card.dart';
import '../widgets/organization_invite_by_email_dialog.dart';
import '../widgets/organization_members_section.dart';
import '../widgets/organization_pets_section.dart';
import '../widgets/organization_role_labels.dart';

class OrganizationDetailScreen extends ConsumerStatefulWidget {
  const OrganizationDetailScreen({super.key, required this.orgId});

  final String orgId;

  @override
  ConsumerState<OrganizationDetailScreen> createState() =>
      _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState
    extends ConsumerState<OrganizationDetailScreen> {
  bool _petsExpanded = true;
  bool _hiddenExpanded = false;

  String get orgId => widget.orgId;

  String _localizedTypeLabel(AppLocalizations l, OrganizationType type) {
    switch (type) {
      case OrganizationType.professional:
        return l.orgTypeProfessional;
      case OrganizationType.charity:
        return l.orgTypeCharity;
    }
  }

  String _localizedRoleLabel(AppLocalizations l, OrgMemberRole role) {
    return localizedOrgMemberRole(l, role);
  }

  @override
  Widget build(BuildContext context) {
    final orgsAsync = ref.watch(organizationListProvider);
    final isSuperUser = ref.watch(isOrgSuperUserProvider(orgId));
    final isOrgAdmin = ref.watch(isOrgAdminProvider(orgId));
    final membersAsync = isOrgAdmin
        ? ref.watch(orgMembersProvider(orgId))
        : const AsyncValue<List<OrganizationMember>>.data([]);
    final petsAsync = isOrgAdmin
        ? ref.watch(orgPetsProvider(orgId))
        : const AsyncValue<List<Pet>>.data([]);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return orgsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: AppLogoTitle(title: l.organizations)),
        body: Center(child: Text('$e')),
      ),
      data: (orgs) {
        final org = orgs.where((o) => o.id == orgId).firstOrNull;
        if (org == null) {
          return Scaffold(
            appBar: AppBar(title: AppLogoTitle(title: l.organizations)),
            body: const Center(child: Text('Not found')),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.orgBlue,
          appBar: AppBar(
            backgroundColor: AppTheme.orgBlue,
            title: AppLogoTitle(title: org.name),
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
                  if (isOrgAdmin) ...[
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
                  ],
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
              OrganizationInfoCard(
                org: org,
                theme: theme,
                colorScheme: colorScheme,
                l: l,
                localizedTypeLabel: _localizedTypeLabel,
              ),
              const SizedBox(height: 16),
              OrganizationContactCard(
                org: org,
                theme: theme,
                colorScheme: colorScheme,
              ),
              if (isOrgAdmin) ...[
                const SizedBox(height: 16),
                OrganizationMembersSection(
                  membersAsync: membersAsync,
                  isSuperUser: isOrgAdmin,
                  theme: theme,
                  colorScheme: colorScheme,
                  l: l,
                  localizedRoleLabel: _localizedRoleLabel,
                  onAddUser: () => showOrganizationInviteByEmailDialog(
                    context: context,
                    ref: ref,
                    orgId: orgId,
                  ),
                ),
                const SizedBox(height: 16),
                OrganizationPetsSection(
                  petsAsync: petsAsync,
                  isSuperUser: isOrgAdmin,
                  theme: theme,
                  colorScheme: colorScheme,
                  l: l,
                  orgId: orgId,
                  petsExpanded: _petsExpanded,
                  onToggleExpand: () => setState(() => _petsExpanded = !_petsExpanded),
                  onAddPet: () => context.push('/add?orgId=$orgId'),
                ),
                const SizedBox(height: 16),
                OrganizationArchivedSection(
                  theme: theme,
                  colorScheme: colorScheme,
                  l: l,
                  onTap: () => context.push('/organizations/$orgId/archived'),
                ),
              ],
              if (isOrgAdmin) ...[
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final hiddenAsync = ref.watch(hiddenSharedPetsProvider);
                    final hiddenPets = hiddenAsync.valueOrNull ?? [];
                    final orgHidden =
                        hiddenPets.where((p) => p.organizationId == orgId).toList();
                    return OrganizationHiddenSharedPetsSection(
                      orgHidden: orgHidden,
                      theme: theme,
                      colorScheme: colorScheme,
                      l: l,
                      hiddenExpanded: _hiddenExpanded,
                      onToggleExpand: () =>
                          setState(() => _hiddenExpanded = !_hiddenExpanded),
                      onUnhide: (pet) async {
                        await ref
                            .read(hiddenSharedPetsProvider.notifier)
                            .unhideSharedPet(pet.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.petUnhidden(pet.name))),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref,
      String action, Organization org) async {
    switch (action) {
      case 'invite':
        showOrganizationInviteByEmailDialog(
          context: context,
          ref: ref,
          orgId: orgId,
        );
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

