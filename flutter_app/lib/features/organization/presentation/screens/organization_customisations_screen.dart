import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/org_permissions_providers.dart';
import '../utils/org_screen_theme.dart';
import '../widgets/org_dashboard/org_section_card.dart';

class OrganizationCustomisationsScreen extends ConsumerWidget {
  const OrganizationCustomisationsScreen({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(viewerPermissionOverridesProvider(orgId));
    final l = AppLocalizations.of(context)!;

    return orgThemed(
      child: Scaffold(
        appBar: AppBar(
          title: AppLogoTitle(title: l.orgCustomisationsTitle),
          leading: IconButton(
            key: const Key('org_customisations_back'),
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => context.pop(),
          ),
        ),
        body: ListView(
          key: const Key('org_customisations_screen'),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l.orgCustomisationsIntro,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OrgSectionCard(
              testKey: const Key('org_customisations_templates'),
              icon: Icons.description_outlined,
              title: l.orgCustomisationsTemplatesTitle,
              subtitle: l.orgCustomisationsTemplatesSubtitle,
              semanticsLabel: l.orgCustomisationsTemplatesTitle,
              onTap: () => context.push('/o/orgs/$orgId/customisations/templates'),
            ),
            const SizedBox(height: 12),
            OrgSectionCard(
              testKey: const Key('org_customisations_roles'),
              icon: Icons.admin_panel_settings_outlined,
              title: l.orgCustomisationsRolesTitle,
              subtitle: l.orgCustomisationsRolesSubtitle,
              semanticsLabel: l.orgCustomisationsRolesTitle,
              onTap: () => context.push('/o/orgs/$orgId/customisations/roles'),
            ),
          ],
        ),
      ),
    );
  }
}
