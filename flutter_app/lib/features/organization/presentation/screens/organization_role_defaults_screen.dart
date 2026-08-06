import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/services/org_permissions.dart';
import '../providers/org_permissions_providers.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';

const _editableTiers = ['associate', 'admin'];
const _superAdminTier = 'super_admin';

const Map<String, List<String>> _permissionBundleGroups = {
  permissionBundleFosterAdmin: [
    'manage_fosters',
    'review_foster_onboarding',
    'contact_fosters',
    'confirm_foster_competencies',
    'home_visits',
  ],
  permissionBundlePetAdmin: [
    'manage_pets',
    'manage_fostering_sessions',
    'transfer_pet_ownership',
  ],
  permissionBundleTeamAdmin: ['manage_admin_contacts', 'manage_members'],
};

class OrganizationRoleDefaultsScreen extends ConsumerStatefulWidget {
  const OrganizationRoleDefaultsScreen({super.key, required this.orgId});

  final String orgId;

  @override
  ConsumerState<OrganizationRoleDefaultsScreen> createState() =>
      _OrganizationRoleDefaultsScreenState();
}

class _OrganizationRoleDefaultsScreenState
    extends ConsumerState<OrganizationRoleDefaultsScreen> {
  String _selectedTier = 'associate';
  Set<String> _draftGranted = {};
  String? _loadedTier;
  bool _busy = false;

  bool get _isReadOnly => _selectedTier == _superAdminTier;

  bool get _isDirty {
    if (_loadedTier != _selectedTier) return false;
    final defaultsAsync = ref.read(
      rolePermissionDefaultsProvider(widget.orgId),
    );
    final data = defaultsAsync.valueOrNull;
    if (data == null) return false;
    final tierData = _tierData(data, _selectedTier);
    final saved = _effectiveKeys(tierData).toSet();
    return !_setEquals(saved, _draftGranted);
  }

  Map<String, dynamic> _tierData(Map<String, dynamic> data, String tier) {
    final tiers = data['tiers'] as Map<String, dynamic>? ?? {};
    return tiers[tier] as Map<String, dynamic>? ?? {};
  }

  List<String> _effectiveKeys(Map<String, dynamic> tierData) {
    return (tierData['effective_defaults'] as List? ?? []).cast<String>();
  }

  List<String> _allPermissionKeys(Map<String, dynamic> data) {
    return (data['permission_keys'] as List? ??
            g0PermissionDefaults.keys.toList())
        .cast<String>();
  }

  void _syncDraftFromData(Map<String, dynamic> data) {
    final tierData = _tierData(data, _selectedTier);
    _draftGranted = _effectiveKeys(tierData).toSet();
    _loadedTier = _selectedTier;
  }

  String _tierLabel(AppLocalizations l, String tier) {
    switch (tier) {
      case 'associate':
        return l.orgRoleDefaultsTierAssociate;
      case 'admin':
        return l.orgRoleDefaultsTierAdmin;
      case _superAdminTier:
        return l.orgRoleDefaultsTierSuperAdmin;
      default:
        return tier;
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

  Future<bool> _confirmDiscard() async {
    if (!_isDirty || !mounted) return true;
    final l = AppLocalizations.of(context)!;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.orgRoleDefaultsUnsavedTitle),
        content: Text(l.orgRoleDefaultsUnsavedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.orgRoleDefaultsDiscard),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _onTierSelected(String? tier) async {
    if (tier == null || tier == _selectedTier) return;
    if (!await _confirmDiscard()) return;
    setState(() {
      _selectedTier = tier;
      _loadedTier = null;
    });
  }

  Future<void> _save() async {
    if (_isReadOnly || !_isDirty) return;
    final l = AppLocalizations.of(context)!;
    final tierLabel = _tierLabel(l, _selectedTier);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.orgRoleDefaultsConfirmTitle),
        content: Text(l.orgRoleDefaultsConfirmBody(tierLabel)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.orgRoleDefaultsSave),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(rolePermissionDefaultsProvider(widget.orgId).notifier)
          .saveTier(_selectedTier, _draftGranted.toList()..sort());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.orgRoleDefaultsSaved(tierLabel))),
        );
        setState(() => _loadedTier = _selectedTier);
      }
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

  List<String> _ungroupedKeys(List<String> allKeys) {
    final grouped = _permissionBundleGroups.values
        .expand((keys) => keys)
        .toSet();
    return allKeys.where((key) => !grouped.contains(key)).toList()..sort();
  }

  Widget _permissionSwitch(
    AppLocalizations l,
    String key, {
    required bool readOnly,
  }) {
    final granted = _draftGranted.contains(key);
    return SwitchListTile(
      key: Key('org_role_default_$key'),
      title: Text(_permissionLabel(l, key)),
      value: granted,
      onChanged: readOnly || _busy
          ? null
          : (value) {
              setState(() {
                if (value) {
                  _draftGranted.add(key);
                } else {
                  _draftGranted.remove(key);
                }
              });
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(viewerPermissionOverridesProvider(widget.orgId));
    final defaultsAsync = ref.watch(
      rolePermissionDefaultsProvider(widget.orgId),
    );
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: OrgShellScaffold(
        title: l.orgRoleDefaultsTitle,
        orgId: widget.orgId,
        navVariant: OrgNavTitleVariant.withOrgLogo,
        leadingKey: const Key('org_role_defaults_back'),
        contextualActions: [
          if (!_isReadOnly)
            TextButton(
              key: const Key('org_role_defaults_save'),
              onPressed: _busy || !_isDirty ? null : _save,
              child: Text(l.orgRoleDefaultsSave),
            ),
        ],
        child: defaultsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (data) {
            if (_loadedTier != _selectedTier) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _syncDraftFromData(data));
              });
            }

            final allKeys = _allPermissionKeys(data);
            final readOnly = _isReadOnly;

            return ListView(
              key: const Key('org_role_defaults_screen'),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l.orgRoleDefaultsIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.orgRoleDefaultsTierPrompt,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  key: const Key('org_role_defaults_tier_selector'),
                  segments: [
                    for (final tier in [..._editableTiers, _superAdminTier])
                      ButtonSegment(
                        value: tier,
                        label: Text(_tierLabel(l, tier)),
                      ),
                  ],
                  selected: {_selectedTier},
                  onSelectionChanged: (selection) =>
                      _onTierSelected(selection.first),
                ),
                if (readOnly) ...[
                  const SizedBox(height: 12),
                  Text(
                    l.orgRoleDefaultsReadOnlyHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                for (final entry in _permissionBundleGroups.entries) ...[
                  Text(
                    _bundleLabel(l, entry.key),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...entry.value.map(
                    (key) => _permissionSwitch(l, key, readOnly: readOnly),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  l.orgRoleDefaultsOtherPermissions,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ..._ungroupedKeys(
                  allKeys,
                ).map((key) => _permissionSwitch(l, key, readOnly: readOnly)),
              ],
            );
          },
        ),
      ),
    );
  }
}

bool _setEquals<T>(Set<T> a, Set<T> b) {
  if (a.length != b.length) return false;
  for (final value in a) {
    if (!b.contains(value)) return false;
  }
  return true;
}
