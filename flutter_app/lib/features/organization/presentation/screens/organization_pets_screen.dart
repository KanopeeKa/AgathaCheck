import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/services/foster_visibility.dart';
import '../providers/admin_contact_providers.dart';
import '../providers/organization_providers.dart';
import '../providers/org_pets_screen_providers.dart';
import '../utils/org_pets_care_utils.dart';
import '../widgets/org_pets/org_pets_filter_row.dart';
import '../widgets/org_pets/org_pets_tab_bar.dart';
import '../widgets/org_pets/org_pet_list_item.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';

class OrganizationPetsScreen extends ConsumerWidget {
  const OrganizationPetsScreen({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenDataAsync = ref.watch(orgPetsScreenDataProvider(orgId));
    final viewerRole = ref.watch(orgViewerRoleProvider(orgId));
    final canManagePets = canManageOrgPets(viewerRole, orgId);
    final tab = ref.watch(orgPetsTabProvider(orgId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return OrgShellScaffold(
      title: l.orgPets,
      orgId: orgId,
      navVariant: OrgNavTitleVariant.withOrgLogo,
      leadingKey: const Key('org_pets_back'),
      contextualActions: [
        if (canManagePets)
          IconButton(
            key: const Key('org_add_pet_nav'),
            icon: const Icon(Icons.add),
            tooltip: l.orgAddPet,
            onPressed: () => context.push('/add?orgId=$orgId'),
          ),
      ],
      child: screenDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('$e'),
              const SizedBox(height: 8),
              ElevatedButton(
                key: const Key('org_pets_retry'),
                onPressed: () {
                  ref.invalidate(orgPetsProvider(orgId));
                  ref.invalidate(orgPlacementsProvider(orgId));
                  ref.invalidate(orgArchivedPetsProvider(orgId));
                },
                child: Text(l.retry),
              ),
            ],
          ),
        ),
        data: (screenData) {
          final filtered = screenData.filteredEntries;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OrgPetsTabBar(orgId: orgId),
              if (tab == OrgPetsTab.needAttention)
                const OrgPetsNeedAttentionHelp(),
              OrgPetsFilterRow(orgId: orgId),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          l.orgPetsEmptyTab,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        key: const Key('org_pets_list'),
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: OrgPetListItem(
                              entry: entry,
                              orgId: orgId,
                              isOrgAdmin: canManagePets,
                              showAttentionReason:
                                  tab == OrgPetsTab.needAttention,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
