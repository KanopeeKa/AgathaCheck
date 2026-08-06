import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization_member.dart';
import '../../domain/services/org_permissions.dart';
import '../controllers/org_dashboard_menu.dart';
import '../providers/organization_providers.dart';
import '../utils/org_screen_theme.dart';
import '../widgets/org_dashboard/legal_documents_drawer.dart';
import '../widgets/org_dashboard/org_section_card.dart';

class OrganizationDashboardScreen extends ConsumerStatefulWidget {
  const OrganizationDashboardScreen({super.key, required this.orgId});

  final String orgId;

  @override
  ConsumerState<OrganizationDashboardScreen> createState() =>
      _OrganizationDashboardScreenState();
}

class _OrganizationDashboardScreenState
    extends ConsumerState<OrganizationDashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String get orgId => widget.orgId;

  bool _can(OrgMemberRole? role, String permissionKey) {
    if (role == null) return false;
    return hasPermission(role, orgId, permissionKey);
  }

  @override
  Widget build(BuildContext context) {
    final orgsAsync = ref.watch(organizationListProvider);
    final viewerRole = ref.watch(orgViewerRoleProvider(orgId));
    final l = AppLocalizations.of(context)!;

    return orgsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
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

        final canEditOrg = _can(viewerRole, 'manage_permissions');

        return orgThemed(
          child: Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: AppLogoTitle(title: org.name),
              leading: IconButton(
                key: const Key('org_dashboard_back'),
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => context.go('/o/orgs'),
              ),
              actions: [
                PopupMenuButton<String>(
                  key: const Key('org_dashboard_menu'),
                  tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                  onSelected: (value) => handleOrgDashboardMenuAction(
                    context: context,
                    ref: ref,
                    orgId: orgId,
                    action: value,
                    org: org,
                  ),
                  itemBuilder: (context) => buildOrgDashboardMenuItems(
                    context: context,
                    ref: ref,
                    orgId: orgId,
                  ),
                ),
              ],
            ),
            endDrawer: LegalDocumentsDrawer(orgId: orgId),
            body: ListView(
              key: const Key('org_dashboard_screen'),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l.orgDashboardIntro,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                OrgSectionCard(
                  testKey: const Key('org_section_presentation'),
                  icon: Icons.storefront_outlined,
                  title: l.orgPresentationTitle,
                  subtitle: l.orgPresentationSubtitle,
                  semanticsLabel: l.orgPresentationTitle,
                  onTap: () => context.push('/o/orgs/$orgId/presentation'),
                ),
                const SizedBox(height: 12),
                OrgSectionCard(
                  testKey: const Key('org_section_admin_contacts'),
                  icon: Icons.contact_phone_outlined,
                  title: l.adminContactsTitle,
                  subtitle: l.adminContactsDescription,
                  semanticsLabel: l.adminContactsTitle,
                  onTap: () =>
                      context.push('/o/orgs/$orgId/people?filter=admins'),
                ),
                if (_can(viewerRole, 'manage_fosters')) ...[
                  const SizedBox(height: 12),
                  OrgSectionCard(
                    testKey: const Key('org_section_fosters'),
                    icon: Icons.home_work_outlined,
                    title: l.manageFostersTitle,
                    subtitle: l.manageFostersDescription,
                    semanticsLabel: l.manageFostersTitle,
                    onTap: () => context.push('/o/orgs/$orgId/fosters'),
                  ),
                ],
                const SizedBox(height: 12),
                OrgSectionCard(
                  testKey: const Key('org_section_pets'),
                  icon: Icons.pets,
                  title: l.orgPets,
                  subtitle: l.orgDashboardPetsSubtitle,
                  semanticsLabel: l.orgPets,
                  onTap: () => context.push('/o/orgs/$orgId/pets'),
                ),
                if (_can(viewerRole, 'manage_members')) ...[
                  const SizedBox(height: 12),
                  OrgSectionCard(
                    testKey: const Key('org_section_connections'),
                    icon: Icons.hub_outlined,
                    title: l.orgConnections,
                    subtitle: l.orgDashboardConnectionsSubtitle,
                    semanticsLabel: l.orgConnections,
                    onTap: () => context.push('/o/orgs/$orgId/connections'),
                  ),
                ],
                const SizedBox(height: 12),
                OrgSectionCard(
                  testKey: const Key('org_section_legal_documents'),
                  icon: Icons.description_outlined,
                  title: l.orgLegalDocumentsTitle,
                  subtitle: l.orgLegalDocumentsSubtitle,
                  semanticsLabel: l.orgLegalDocumentsTitle,
                  onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                ),
                if (canEditOrg) ...[
                  const SizedBox(height: 12),
                  OrgSectionCard(
                    testKey: const Key('org_section_edit'),
                    icon: Icons.settings_outlined,
                    title: l.editOrganization,
                    subtitle: l.orgDashboardEditSubtitle,
                    semanticsLabel: l.editOrganization,
                    onTap: () => context.push('/o/orgs/$orgId/edit'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
