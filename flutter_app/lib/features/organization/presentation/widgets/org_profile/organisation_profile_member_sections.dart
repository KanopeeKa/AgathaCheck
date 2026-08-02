import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import 'organisation_profile_admin_contacts.dart';
import 'organisation_profile_connections.dart';
import 'organisation_profile_pets.dart';
import 'organisation_profile_section.dart';

/// Member-tier profile sections gated by view_* permissions.
class OrganisationProfileMemberSections extends StatelessWidget {
  const OrganisationProfileMemberSections({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OrganisationProfileSection(
            orgId: orgId,
            permissionKey: 'view_admin_contacts',
            sectionKey: const Key('org_profile_section_admin_contacts'),
            title: l.adminContactsTitle,
            preview: OrganisationProfileAdminContacts(orgId: orgId),
            manageLinkLabel: l.adminContactsTitle,
            onManage: () => context.push('/o/orgs/$orgId/admin-contacts'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OrganisationProfileSection(
            orgId: orgId,
            permissionKey: 'view_org_internal',
            sectionKey: const Key('org_profile_section_fosters'),
            title: l.fosterParents,
            preview: Text(l.manageFostersDescription, style: mutedStyle),
            manageLinkLabel: l.orgPermissionManageFosters,
            managePermissionKey: 'manage_fosters',
            onManage: () => context.push('/o/orgs/$orgId/fosters'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OrganisationProfileSection(
            orgId: orgId,
            permissionKey: 'view_fostering_sessions',
            sectionKey: const Key('org_profile_section_fostering_sessions'),
            title: l.orgProfileFosteringSessionsTitle,
            preview: Text(
              l.fosteringSessionPreparationPlaceholder,
              style: mutedStyle,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OrganisationProfileSection(
            orgId: orgId,
            permissionKey: 'view_org_pets',
            sectionKey: const Key('org_profile_section_pets'),
            title: l.orgPets,
            preview: OrganisationProfilePets(orgId: orgId),
            manageLinkLabel: l.orgPermissionManagePets,
            managePermissionKey: 'manage_pets',
            onManage: () => context.push('/o/orgs/$orgId/pets'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OrganisationProfileSection(
            orgId: orgId,
            permissionKey: 'view_connections',
            sectionKey: const Key('org_profile_section_connections'),
            title: l.orgConnections,
            preview: OrganisationProfileConnections(orgId: orgId),
            manageLinkLabel: l.orgPermissionManageMembers,
            managePermissionKey: 'manage_members',
            onManage: () => context.push('/o/orgs/$orgId/connections'),
          ),
        ),
      ],
    );
  }
}
