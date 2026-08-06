import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization_member.dart';
import '../../domain/services/org_permissions.dart';
import '../providers/organization_providers.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';
import '../widgets/org_roles_permissions/staged_permissions_controller.dart';
import '../widgets/org_roles_permissions/tri_state_permission_toggle.dart';
import '../widgets/organization_role_labels.dart';

class OrganizationRolesPermissionsScreen extends ConsumerStatefulWidget {
  const OrganizationRolesPermissionsScreen({
    super.key,
    required this.orgId,
    this.initialPeopleIds = const [],
  });

  final String orgId;
  final List<String> initialPeopleIds;

  @override
  ConsumerState<OrganizationRolesPermissionsScreen> createState() =>
      _OrganizationRolesPermissionsScreenState();
}

class _OrganizationRolesPermissionsScreenState
    extends ConsumerState<OrganizationRolesPermissionsScreen> {
  final Set<String> _selectedUserIds = {};
  StagedPermissionsController? _controller;
  bool _loadingBaselines = false;
  bool _busy = false;
  bool _appliedInitialSelection = false;
  final _searchController = TextEditingController();

  String get orgId => widget.orgId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyInitialSelection(List<OrganizationMember> members) {
    if (_appliedInitialSelection || widget.initialPeopleIds.isEmpty) return;
    final activeIds = members
        .where((m) => !m.role.isPending)
        .map((m) => m.userId)
        .toSet();
    for (final id in widget.initialPeopleIds) {
      if (activeIds.contains(id)) _selectedUserIds.add(id);
    }
    _appliedInitialSelection = true;
  }

  Future<void> _loadBaselines(List<OrganizationMember> members) async {
    if (_selectedUserIds.isEmpty) {
      setState(() => _controller = null);
      return;
    }
    setState(() => _loadingBaselines = true);
    try {
      final token = ref.read(orgTokenProvider);
      if (token == null) return;
      final repo = ref.read(organizationRepositoryProvider);
      final baselines = <String, MemberPermissionBaseline>{};
      for (final userId in _selectedUserIds) {
        final data = await repo.getMemberPermissions(orgId, userId, token);
        baselines[userId] = MemberPermissionBaseline.fromApi(data);
      }
      if (!mounted) return;
      setState(() {
        _controller = StagedPermissionsController(baselines: baselines);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loadingBaselines = false);
    }
  }

  void _ensureDefaultSelection(List<OrganizationMember> activeMembers) {
    if (_selectedUserIds.isNotEmpty || activeMembers.isEmpty) return;
    _selectedUserIds.add(activeMembers.first.userId);
  }

  Future<void> _confirmLeave() async {
    final l = AppLocalizations.of(context)!;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.orgRolesPermissionsUnsavedTitle),
        content: Text(l.orgRolesPermissionsUnsavedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.orgRolesPermissionsStay),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.orgRolesPermissionsDiscard),
          ),
        ],
      ),
    );
    if (leave == true && mounted) context.pop();
  }

  Future<void> _confirmRolePreset(
    AppLocalizations l,
    OrgMemberRole role,
    List<OrganizationMember> activeMembers,
  ) async {
    final roleLabel = localizedOrgMemberRole(l, role);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.orgRolesPermissionsPresetConfirmTitle(roleLabel)),
        content: Text(l.orgRolesPermissionsPresetConfirmBody(roleLabel)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.orgRolesPermissionsApplyRolePreset(roleLabel)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _controller == null) return;
    setState(() {
      _controller = _controller!.applyRolePreset(role, _selectedUserIds);
    });
  }

  Future<void> _saveChanges(AppLocalizations l) async {
    final controller = _controller;
    if (controller == null) return;
    final changes = controller.buildSaveChanges();
    if (changes.isEmpty) return;

    setState(() => _busy = true);
    try {
      final token = ref.read(orgTokenProvider)!;
      final repo = ref.read(organizationRepositoryProvider);
      await repo.batchMemberPermissions(orgId, changes, token);
      ref.invalidate(orgAuditEventsProvider(orgId));
      ref.invalidate(orgEffectivePermissionsProvider(orgId));
      for (final userId in _selectedUserIds) {
        ref.invalidate(
          memberPermissionsProvider((orgId: orgId, userId: userId)),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.orgRolesPermissionsSaved)));
      await _loadBaselines(
        ref
                .read(orgMembersProvider(orgId))
                .valueOrNull
                ?.where((m) => !m.role.isPending)
                .toList() ??
            [],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _permissionLabel(AppLocalizations l, String key) {
    switch (key) {
      case 'manage_fosters':
        return l.orgPermissionManageFosters;
      case 'manage_pets':
        return l.orgPermissionManagePets;
      case 'manage_members':
        return l.orgPermissionManageMembers;
      case 'manage_document_templates':
        return l.orgPermissionManageDocumentTemplates;
      case 'manage_permissions':
        return l.orgPermissionManagePermissions;
      default:
        return key.replaceAll('_', ' ');
    }
  }

  String _bundleLabel(AppLocalizations l, String name) {
    switch (name) {
      case permissionBundleFosterAdmin:
        return l.orgPermissionBundleFosterAdmin;
      case permissionBundlePetAdmin:
        return l.orgPermissionBundlePetAdmin;
      case permissionBundleTeamAdmin:
        return l.orgPermissionBundleTeamAdmin;
      default:
        return name.replaceAll('_', ' ');
    }
  }

  Widget _buildSelectedPeopleChips(
    AppLocalizations l,
    List<OrganizationMember> activeMembers,
  ) {
    final membersById = {for (final m in activeMembers) m.userId: m};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.orgRolesPermissionsSelectedPeople,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedUserIds.map((userId) {
            final member = membersById[userId];
            final label = member?.displayName ?? userId;
            return InputChip(
              key: Key('org_roles_person_chip_$userId'),
              label: Text(label),
              onDeleted: _busy
                  ? null
                  : () {
                      setState(() => _selectedUserIds.remove(userId));
                      _loadBaselines(activeMembers);
                    },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Autocomplete<OrganizationMember>(
          key: const Key('org_roles_member_search'),
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.trim().toLowerCase();
            return activeMembers.where((member) {
              if (_selectedUserIds.contains(member.userId)) return false;
              if (query.isEmpty) return true;
              return member.displayName.toLowerCase().contains(query) ||
                  member.email.toLowerCase().contains(query);
            });
          },
          displayStringForOption: (member) => member.displayName,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: l.orgRolesPermissionsAddMember,
                prefixIcon: const Icon(Icons.search),
              ),
            );
          },
          onSelected: (member) {
            setState(() => _selectedUserIds.add(member.userId));
            _searchController.clear();
            _loadBaselines(activeMembers);
          },
        ),
      ],
    );
  }

  Widget _buildPresetButtons(
    AppLocalizations l,
    List<OrganizationMember> activeMembers,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: permissionRoleTierPresets.map((role) {
        final roleLabel = localizedOrgMemberRole(l, role);
        return FilledButton.tonal(
          key: Key('org_apply_role_preset_${role.toWire()}'),
          onPressed: _busy || _controller == null
              ? null
              : () => _confirmRolePreset(l, role, activeMembers),
          child: Text(l.orgRolesPermissionsApplyRolePreset(roleLabel)),
        );
      }).toList(),
    );
  }

  Widget _buildPermissionToggle(
    AppLocalizations l,
    String permissionKey,
    StagedPermissionsController controller,
  ) {
    final aggregate = controller.aggregateState(
      permissionKey,
      _selectedUserIds,
    );
    final pending = controller.hasPendingChange(
      permissionKey,
      _selectedUserIds,
    );
    final canToggle = controller.canToggleKey(permissionKey, _selectedUserIds);

    return ListTile(
      key: Key('org_permission_toggle_$permissionKey'),
      title: Text(_permissionLabel(l, permissionKey)),
      trailing: SizedBox(
        width: 72,
        child: TriStatePermissionToggle(
          value: aggregate,
          enabled: canToggle && !_busy,
          showPending: pending,
          semanticsLabel: pending
              ? l.orgRolesPermissionsPendingChange
              : _permissionLabel(l, permissionKey),
          onChanged: canToggle && !_busy
              ? (granted) {
                  setState(() {
                    _controller = controller.stageToggle(
                      permissionKey,
                      _selectedUserIds,
                      granted,
                    );
                  });
                }
              : null,
        ),
      ),
    );
  }

  Widget _buildDetailedPermissions(
    AppLocalizations l,
    StagedPermissionsController controller,
  ) {
    final children = <Widget>[
      ...permissionViewKeysOrdered.map(
        (key) => _buildPermissionToggle(l, key, controller),
      ),
      for (final entry in permissionBundleKeyGroups.entries) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            _bundleLabel(l, entry.key),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ...entry.value.map((key) => _buildPermissionToggle(l, key, controller)),
      ],
    ];

    return ExpansionTile(
      key: const Key('org_roles_detailed_permissions'),
      title: Text(l.orgRolesPermissionsDetailedTitle),
      initiallyExpanded: false,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(viewerPermissionOverridesProvider(orgId));
    final membersAsync = ref.watch(orgMembersProvider(orgId));
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasUnsaved = _controller?.hasUnsavedChanges ?? false;

    return PopScope(
      canPop: !hasUnsaved,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && hasUnsaved) _confirmLeave();
      },
      child: OrgShellScaffold(
        title: l.orgCustomisationsRolesTitle,
        orgId: orgId,
        navVariant: OrgNavTitleVariant.withOrgLogo,
        leadingKey: const Key('org_roles_permissions_back'),
        child: membersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (members) {
            final activeMembers = members
                .where((m) => !m.role.isPending)
                .toList();
            _applyInitialSelection(members);
            _ensureDefaultSelection(activeMembers);
            if (!_loadingBaselines &&
                _controller == null &&
                _selectedUserIds.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _loadBaselines(activeMembers),
              );
            }

            return ListView(
              key: const Key('org_roles_permissions_screen'),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l.orgRolesPermissionsIntro,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSelectedPeopleChips(l, activeMembers),
                const SizedBox(height: 16),
                if (_selectedUserIds.isEmpty)
                  Text(l.orgRolesPermissionsSelectPeople)
                else ...[
                  _buildPresetButtons(l, activeMembers),
                  const SizedBox(height: 16),
                  if (_loadingBaselines || _controller == null)
                    const Center(child: CircularProgressIndicator())
                  else
                    _buildDetailedPermissions(l, _controller!),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      key: const Key('org_roles_permissions_save'),
                      onPressed: !_busy && hasUnsaved
                          ? () => _saveChanges(l)
                          : null,
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l.orgRolesPermissionsSave),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
