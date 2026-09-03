import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/presentation/widgets/pet_card.dart';
import '../providers/organization_providers.dart';
import '../providers/shelter_tasks_provider.dart';
import '../widgets/org_discover_nav_row.dart';
import '../widgets/org_hub_section_header.dart';
import '../widgets/org_membership_tile.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';
import '../widgets/shelter_tasks/shelter_tasks_preview.dart';

class OrganizationListScreen extends ConsumerWidget {
  const OrganizationListScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgsAsync = ref.watch(organizationListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    final body = RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(organizationListProvider);
        ref.invalidate(pendingOrgInvitesProvider);
        ref.invalidate(shelterTasksPreviewProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OrgHubSectionHeader(
            title: l.organisationsDashboardTitle,
            subtitle: l.orgMembershipByEmailInvite,
          ),
          const SizedBox(height: 16),
          OrgHubSectionHeader(title: l.myOrganizations),
          const SizedBox(height: 10),
          orgsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text('$error'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    key: const Key('org_retry_button'),
                    onPressed: () => ref.invalidate(organizationListProvider),
                    child: Text(l.retry),
                  ),
                ],
              ),
            ),
            data: (orgs) {
              if (orgs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          Icons.business_outlined,
                          size: 80,
                          color: colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l.orgNoOrganizations,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.createOrJoinOrganization,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final tileWidth = OrgMembershipTile.tileWidthFor(
                    constraints.maxWidth,
                  );
                  return Wrap(
                    key: const Key('org_membership_grid'),
                    spacing: PetCard.tileSpacing,
                    runSpacing: PetCard.tileSpacing,
                    children: [
                      for (final org in orgs)
                        OrgMembershipTile(
                          organization: org,
                          tileWidth: tileWidth,
                          onTap: () => context.push('/o/orgs/${org.id}'),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
          const ShelterTasksPreview(),
          const SizedBox(height: 20),
          OrgHubSectionHeader(
            title: l.discoverOrganizations,
            subtitle: l.orgMembershipByEmailInvite,
          ),
          const SizedBox(height: 10),
          const OrgDiscoverNavRow(),
        ],
      ),
    );

    if (embeddedInShell) {
      return body;
    }

    return OrgShellScaffold(
      title: l.organisationsDashboardTitle,
      navVariant: OrgNavTitleVariant.dashboard,
      leadingKey: const Key('org_back_button'),
      onBack: () => context.go('/'),
      child: body,
    );
  }
}
