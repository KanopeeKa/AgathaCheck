import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/services/org_permissions.dart';
import '../providers/organization_providers.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';

class OrganizationRolesPermissionsScreen extends ConsumerStatefulWidget {
  const OrganizationRolesPermissionsScreen({super.key, required this.orgId});

  final String orgId;

  @override
  ConsumerState<OrganizationRolesPermissionsScreen> createState() =>
      _OrganizationRolesPermissionsScreenState();
}

class _OrganizationRolesPermissionsScreenState
    extends ConsumerState<OrganizationRolesPermissionsScreen> {
  String? _selectedUserId;
  bool _busy = false;

  String get orgId => widget.orgId;

  MemberPermissionsKey? get _permissionsKey {
    final userId = _selectedUserId;
    if (userId == null) return null;
    return (orgId: orgId, userId: userId);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
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

  @override
  Widget build(BuildContext context) {
    ref.watch(viewerPermissionOverridesProvider(orgId));
    final membersAsync = ref.watch(orgMembersProvider(orgId));
    final bundlesAsync = ref.watch(permissionBundlesProvider(orgId));
    final auditAsync = ref.watch(orgAuditEventsProvider(orgId));
    final permissionsKey = _permissionsKey;
    final permissionsAsync = permissionsKey == null
        ? null
        : ref.watch(memberPermissionsProvider(permissionsKey));
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return OrgShellScaffold(
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
          _selectedUserId ??= activeMembers.firstOrNull?.userId;

          return ListView(
            key: const Key('org_roles_permissions_screen'),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l.orgRolesPermissionsIntro,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('org_roles_member_dropdown'),
                value: _selectedUserId,
                decoration: InputDecoration(
                  labelText: l.orgRolesPermissionsMemberLabel,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                items: activeMembers
                    .map(
                      (member) => DropdownMenuItem(
                        value: member.userId,
                        child: Text(
                          '${member.firstName} ${member.lastName}'.trim(),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _selectedUserId = value),
              ),
              const SizedBox(height: 16),
              bundlesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (bundleData) {
                  final presets = (bundleData['presets'] as List? ?? [])
                      .cast<Map<String, dynamic>>();
                  if (presets.isEmpty) return const SizedBox.shrink();
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets.map((preset) {
                      final name = preset['name'] as String;
                      return FilledButton.tonal(
                        key: Key('org_apply_bundle_$name'),
                        onPressed: _busy || permissionsKey == null
                            ? null
                            : () => _run(() async {
                                await ref
                                    .read(
                                      memberPermissionsProvider(
                                        permissionsKey,
                                      ).notifier,
                                    )
                                    .applyBundle(name);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l.orgRolesPermissionsBundleApplied(
                                          _bundleLabel(l, name),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              }),
                        child: Text(
                          l.orgRolesPermissionsApplyBundle(
                            _bundleLabel(l, name),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                l.orgRolesPermissionsEffectiveTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (permissionsKey == null)
                Text(l.orgRolesPermissionsSelectMember)
              else
                permissionsAsync!.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('$e'),
                  data: (data) {
                    final effectiveSet =
                        (data['effective_permissions'] as List? ?? [])
                            .cast<String>()
                            .toSet();
                    final overrides = (data['overrides'] as List? ?? [])
                        .cast<Map<String, dynamic>>();
                    final overrideKeys = overrides
                        .map((row) => row['permission_key'] as String)
                        .toSet();
                    final allKeys = g0PermissionDefaults.keys.toList()..sort();

                    return Column(
                      children: allKeys.map((key) {
                        final isEffective = effectiveSet.contains(key);
                        final hasOverride = overrideKeys.contains(key);
                        final fromRole = isEffective && !hasOverride;
                        return SwitchListTile(
                          key: Key('org_permission_toggle_$key'),
                          title: Text(_permissionLabel(l, key)),
                          subtitle: fromRole
                              ? Text(l.orgRolesPermissionsRoleDefault)
                              : hasOverride
                              ? Text(l.orgRolesPermissionsOverrideActive)
                              : null,
                          value: isEffective,
                          onChanged: _busy
                              ? null
                              : fromRole
                              ? null
                              : (enabled) => _run(() async {
                                  final notifier = ref.read(
                                    memberPermissionsProvider(
                                      permissionsKey,
                                    ).notifier,
                                  );
                                  if (enabled) {
                                    await notifier.grantPermission(key);
                                  } else {
                                    await notifier.revokePermission(key);
                                  }
                                }),
                          secondary: fromRole
                              ? const Icon(Icons.badge_outlined)
                              : hasOverride
                              ? const Icon(Icons.tune)
                              : const Icon(Icons.lock_open_outlined),
                        );
                      }).toList(),
                    );
                  },
                ),
              const SizedBox(height: 24),
              Text(
                l.orgRolesPermissionsAuditTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              auditAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('$e'),
                data: (events) {
                  if (events.isEmpty) {
                    return Text(l.orgRolesPermissionsAuditEmpty);
                  }
                  final dateFormat = DateFormat.yMMMd().add_jm();
                  return Column(
                    children: events.map((event) {
                      final occurredAt = event['occurred_at'];
                      final timestamp = occurredAt is String
                          ? DateTime.tryParse(occurredAt)
                          : occurredAt is DateTime
                          ? occurredAt
                          : null;
                      final subtitle = timestamp == null
                          ? ''
                          : dateFormat.format(timestamp.toLocal());
                      return ListTile(
                        key: Key('org_audit_${event['id']}'),
                        title: Text(event['action'] as String? ?? ''),
                        subtitle: Text(subtitle),
                        dense: true,
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
