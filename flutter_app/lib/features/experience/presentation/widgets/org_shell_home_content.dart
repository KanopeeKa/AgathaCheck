import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../organization/domain/entities/organization.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../pet_profile/presentation/widgets/pet_card.dart';
import '../../../pet_profile/presentation/widgets/pet_list/due_events_section.dart';
import '../../../pet_profile/presentation/widgets/pet_list/pending_adoption_placements_section.dart';
import '../../../pet_profile/presentation/widgets/pet_list/pending_custody_transfers_section.dart';
import '../../../pet_profile/presentation/widgets/pet_list/pending_foster_placements_section.dart';
import '../../../pet_profile/presentation/widgets/pet_list/pet_list_section_header.dart';
import '../../../organization/presentation/providers/organization_providers.dart';

/// Organisation shell home: due events (org pets) + pets grouped by org.
class OrgShellHomeContent extends ConsumerWidget {
  const OrgShellHomeContent({
    super.key,
    required this.allPets,
    required this.controller,
  });

  final List<Pet> allPets;
  final PetListController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final orgsAsync = ref.watch(organizationListProvider);
    final orgPets = controller.orgShellPets(allPets);
    final orgGroups = controller.getOrgGroups(orgPets);

    return orgsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (orgs) {
        if (orgs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 80,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.orgNoOrganizations,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push('/organizations/new'),
                    icon: const Icon(Icons.add),
                    label: Text(l.create),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (orgs.length == 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('org_home_shelter_settings'),
                    onPressed: () =>
                        context.push('/account/orgs/${orgs.first.id}'),
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: Text(l.shelterSettings),
                  ),
                ),
              ),
            PendingFosterPlacementsSection(),
            PendingAdoptionPlacementsSection(),
            PendingCustodyTransfersSection(),
            DueEventsSection(pets: orgPets, showInlineActions: true),
            ...orgGroups.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PetListSectionHeader(
                    icon: Icons.business,
                    title: entry.key,
                    count: entry.value.length,
                  ),
                  ...entry.value.map(
                    (pet) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PetCard(
                        pet: pet,
                        onTap: () => context.push('/pet/${pet.id}'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        final orgId = entry.value
                            .map((p) => p.organizationId)
                            .whereType<String>()
                            .firstOrNull;
                        if (orgId != null) {
                          context.push('/organizations/$orgId');
                          return;
                        }
                        Organization? match;
                        for (final o in orgs) {
                          if (o.name == entry.key) {
                            match = o;
                            break;
                          }
                        }
                        if (match != null) {
                          context.push('/organizations/${match.id}');
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(l.viewOrganization),
                    ),
                  ),
                ],
              );
            }),
            if (orgPets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    l.orgNoPets,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
