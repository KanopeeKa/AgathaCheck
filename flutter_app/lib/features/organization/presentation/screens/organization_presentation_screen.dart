import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization.dart';
import '../providers/organization_providers.dart';
import '../utils/org_screen_theme.dart';
import '../widgets/org_presentation/org_presentation_contact_block.dart';
import '../widgets/org_presentation/org_presentation_hero.dart';
import '../widgets/org_presentation/org_presentation_legal_block.dart';

class OrganizationPresentationScreen extends ConsumerWidget {
  const OrganizationPresentationScreen({super.key, required this.orgId});

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
    final orgsAsync = ref.watch(organizationListProvider);
    final l = AppLocalizations.of(context)!;

    return orgsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: AppLogoTitle(title: l.orgPresentationTitle)),
        body: Center(child: Text('$e')),
      ),
      data: (orgs) {
        final org = orgs.where((o) => o.id == orgId).firstOrNull;
        if (org == null) {
          return Scaffold(
            appBar: AppBar(title: AppLogoTitle(title: l.orgPresentationTitle)),
            body: const Center(child: Text('Not found')),
          );
        }

        final typeLabel = _localizedTypeLabel(l, org.type);

        return orgThemed(
          child: Scaffold(
            key: const Key('org_presentation_screen'),
            appBar: AppBar(
              title: AppLogoTitle(title: l.orgPresentationTitle),
              leading: IconButton(
                key: const Key('org_presentation_back'),
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => context.pop(),
              ),
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
              ],
            ),
          ),
        );
      },
    );
  }
}
