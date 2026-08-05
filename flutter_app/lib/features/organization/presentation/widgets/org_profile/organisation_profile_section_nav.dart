import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/organization.dart';
import '../../providers/org_provider_connections.dart';
import '../../providers/org_provider_list.dart';
import '../org_permission_gate.dart';

/// Member-tier profile navigation rows (pet-profile Timeline style) — no previews.
class OrganisationProfileSectionNav extends ConsumerWidget {
  const OrganisationProfileSectionNav({super.key, required this.orgId});

  final String orgId;

  Organization? _memberOrg(WidgetRef ref) {
    return ref
        .watch(organizationListProvider)
        .maybeWhen(
          data: (orgs) {
            for (final org in orgs) {
              if (org.id == orgId) return org;
            }
            return null;
          },
          orElse: () => null,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final memberOrg = _memberOrg(ref);
    final petCount = memberOrg?.petCount ?? 0;
    final connectionsAsync = ref.watch(orgConnectionsProvider(orgId));
    final connectionsCount = connectionsAsync.maybeWhen(
      data: (connections) => connections.length,
      orElse: () => null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            OrgPermissionGate(
              orgId: orgId,
              permissionKey: 'view_admin_contacts',
              child: _OrganisationProfileNavRow(
                rowKey: const Key('org_profile_nav_admin_contacts'),
                title: l.adminContactsTitle,
                onTap: () => context.push('/o/orgs/$orgId/admin-contacts'),
              ),
            ),
            OrgPermissionGate(
              orgId: orgId,
              permissionKey: 'view_org_internal',
              child: _OrganisationProfileNavRow(
                rowKey: const Key('org_profile_nav_foster_parents'),
                title: l.fosterParents,
                onTap: () => context.push('/o/orgs/$orgId/fosters'),
              ),
            ),
            OrgPermissionGate(
              orgId: orgId,
              permissionKey: 'view_fostering_sessions',
              child: _OrganisationProfileNavRow(
                rowKey: const Key('org_profile_nav_fostering_sessions'),
                title: l.orgProfileFosteringSessionsTitle,
                onTap: () => context.push('/o/orgs/$orgId/sessions'),
              ),
            ),
            OrgPermissionGate(
              orgId: orgId,
              permissionKey: 'view_org_pets',
              child: _OrganisationProfileNavRow(
                rowKey: const Key('org_profile_nav_pets'),
                title: l.orgPets,
                countLabel: petCount > 0 ? l.petCount(petCount) : null,
                onTap: () => context.push('/o/orgs/$orgId/pets'),
              ),
            ),
            OrgPermissionGate(
              orgId: orgId,
              permissionKey: 'view_connections',
              child: _OrganisationProfileNavRow(
                rowKey: const Key('org_profile_nav_connections'),
                title: l.orgConnections,
                countLabel: connectionsCount != null && connectionsCount > 0
                    ? l.orgConnectionCount(connectionsCount)
                    : null,
                onTap: () => context.push('/o/orgs/$orgId/connections'),
              ),
            ),
            OrgPermissionGate(
              orgId: orgId,
              permissionKey: 'manage_permissions',
              child: _OrganisationProfileNavRow(
                rowKey: const Key('org_profile_nav_administration'),
                title: l.orgCustomisationsTitle,
                onTap: () => context.push('/o/orgs/$orgId/customisations'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrganisationProfileNavRow extends StatelessWidget {
  const _OrganisationProfileNavRow({
    required this.rowKey,
    required this.title,
    required this.onTap,
    this.countLabel,
  });

  final Key rowKey;
  final String title;
  final String? countLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Semantics(
          button: true,
          label: countLabel != null ? '$title, $countLabel' : title,
          child: ListTile(
            key: rowKey,
            contentPadding: EdgeInsets.zero,
            title: Text(title),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (countLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      countLabel!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ),
            onTap: onTap,
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
