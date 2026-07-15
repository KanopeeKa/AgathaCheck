import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../pet_profile/presentation/widgets/fostered_pets_section.dart';
import '../../../pet_profile/presentation/widgets/passed_away_pets_section.dart';
import '../../../pet_profile/presentation/widgets/personal_pets_section.dart';
import '../../../pet_profile/presentation/widgets/pet_list/due_events_section.dart';
import '../../../pet_profile/presentation/widgets/pet_list/pending_adoption_placements_section.dart';
import '../../../pet_profile/presentation/widgets/pet_list/pending_custody_transfers_section.dart';
import '../../../pet_profile/presentation/widgets/pet_list/pending_foster_placements_section.dart';
import '../../../pet_profile/presentation/widgets/pet_list/pending_shares_section.dart';
import '../../../pet_profile/presentation/widgets/pet_list/pet_list_section_header.dart';
import 'guardian_shell_shared_pet_card.dart';

/// Guardian shell home body: due events, My Pets, grouped shared/fostered.
class GuardianShellHomeContent extends ConsumerWidget {
  const GuardianShellHomeContent({
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
    final shellPets = controller.guardianShellPets(allPets);
    final owned = controller.getOwnedPets(shellPets);
    final sharedGroups = controller.groupSharedPets(shellPets);
    final fosterGroups = controller.groupFosteredPets(shellPets);
    final passedAway = shellPets.where((p) => p.passedAway).toList();

    if (shellPets.isEmpty && allPets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 80, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(l.noPetsYet, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              l.addFirstPet,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PendingSharesSection(),
        PendingFosterPlacementsSection(),
        PendingAdoptionPlacementsSection(),
        PendingCustodyTransfersSection(),
        DueEventsSection(pets: shellPets, showInlineActions: true),
        if (owned.isNotEmpty) ...[
          PetListSectionHeader(
            icon: Icons.person,
            title: l.myPets,
            count: owned.length,
          ),
          PersonalPetsSection(
            personalActive: owned,
            orgFilter: null,
            l: l,
            theme: theme,
            ref: ref,
            parentContext: context,
          ),
        ],
        ...sharedGroups.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PetListSectionHeader(
                icon: Icons.people_outline,
                title: l.sharedWithGroupTitle(entry.key),
                count: entry.value.length,
              ),
              ...entry.value.map(
                (pet) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GuardianShellSharedPetCard(
                    pet: pet,
                    l: l,
                    theme: theme,
                    ref: ref,
                    parentContext: context,
                  ),
                ),
              ),
            ],
          );
        }),
        ...fosterGroups.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PetListSectionHeader(
                icon: Icons.home_work_outlined,
                title: l.fosteredViaGroupTitle(entry.key),
                count: entry.value.length,
              ),
              FosteredPetsSection(
                fosteredActive: entry.value,
                orgFilter: null,
                l: l,
                theme: theme,
              ),
            ],
          );
        }),
        PassedAwayPetsSection(allPassedAway: passedAway, theme: theme),
      ],
    );
  }
}
