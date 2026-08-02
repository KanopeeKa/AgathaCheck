import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization.dart';
import '../providers/org_provider_profile.dart';
import '../utils/org_screen_theme.dart';
import '../widgets/org_permission_gate.dart';
import '../widgets/org_presentation/org_presentation_contact_block.dart';
import '../widgets/org_presentation/org_presentation_hero.dart';
import '../widgets/org_presentation/org_presentation_legal_block.dart';
import '../widgets/org_profile/organisation_profile_member_sections.dart';
import '../widgets/organization_emergency_contact_card.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: AppLogoTitle(title: l.orgPresentationTitle)),
        body: Center(child: Text('$e')),
      ),
      data: (profile) {
        final org = profile.organization;
        final typeLabel = _localizedTypeLabel(l, org.type);

        return orgThemed(
          child: Scaffold(
            key: const Key('org_profile_screen'),
            appBar: AppBar(
              title: AppLogoTitle(title: org.name),
              leading: IconButton(
                key: const Key('org_profile_back'),
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => context.go('/o/orgs'),
              ),
              actions: [
                OrgPermissionGate(
                  orgId: orgId,
                  permissionKey: 'manage_permissions',
                  child: IconButton(
                    key: const Key('org_profile_settings'),
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: l.orgProfileSettingsTooltip,
                    onPressed: () => context.push('/o/orgs/$orgId/edit'),
                  ),
                ),
              ],
            ),
            body: ListView(
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
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OrganizationEmergencyContactCard(
                    org: org,
                    theme: theme,
                    colorScheme: colorScheme,
                    l: l,
                  ),
                ),
                if (profile.isMember) ...[
                  const SizedBox(height: 24),
                  OrganisationProfileMemberSections(orgId: orgId),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
