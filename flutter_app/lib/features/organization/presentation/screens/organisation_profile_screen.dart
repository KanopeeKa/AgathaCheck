import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization.dart';
import '../providers/org_provider_profile.dart';
import '../widgets/org_permission_gate.dart';
import '../widgets/org_presentation/org_presentation_contact_block.dart';
import '../widgets/org_presentation/org_presentation_hero.dart';
import '../widgets/org_presentation/org_presentation_legal_block.dart';
import '../widgets/org_profile/organisation_profile_member_sections.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';

class OrganisationProfileScreen extends ConsumerWidget {
  const OrganisationProfileScreen({super.key, required this.orgId});

  final String orgId;

  String _localizedTypeLabel(AppLocalizations l, OrganizationType type) {
    switch (type) {
      case OrganizationType.professional:
        return l.orgTypeProfessional;
      case OrganizationType.charity:
        return l.orgTypeCharity;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(organisationProfileProvider(orgId));
    final l = AppLocalizations.of(context)!;

    return profileAsync.when(
      loading: () => OrgShellScaffold(
        title: l.orgPresentationTitle,
        navVariant: OrgNavTitleVariant.textOnly,
        onBack: () => context.go('/o/orgs'),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => OrgShellScaffold(
        title: l.orgPresentationTitle,
        navVariant: OrgNavTitleVariant.textOnly,
        onBack: () => context.go('/o/orgs'),
        child: Center(child: Text('$e')),
      ),
      data: (profile) {
        final org = profile.organization;
        final typeLabel = _localizedTypeLabel(l, org.type);

        return OrgShellScaffold(
          key: const Key('org_profile_screen'),
          title: org.name,
          navVariant: OrgNavTitleVariant.textOnly,
          leadingKey: const Key('org_profile_back'),
          onBack: () => context.go('/o/orgs'),
          trailingActions: [
            OrgPermissionGate(
              orgId: orgId,
              permissionKey: 'manage_permissions',
              child: IconButton(
                key: const Key('org_profile_edit'),
                icon: const Icon(Icons.edit_outlined),
                tooltip: l.orgProfileEditTooltip,
                onPressed: () => context.push('/o/orgs/$orgId/edit'),
              ),
            ),
          ],
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              OrgPresentationHero(org: org, localizedTypeLabel: typeLabel),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OrgPresentationLegalBlock(org: org, l: l),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OrgPresentationContactBlock(
                  org: org,
                  title: l.orgPresentationContactTitle,
                ),
              ),
              if (profile.isMember) ...[
                const SizedBox(height: 24),
                OrganisationProfileMemberSections(orgId: orgId),
              ],
            ],
          ),
        );
      },
    );
  }
}
