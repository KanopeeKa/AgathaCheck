import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../pet_profile/presentation/widgets/fostered_pets_section.dart';
import '../../../pet_profile/presentation/widgets/passed_away_pets_section.dart';
import '../../../pet_profile/presentation/widgets/personal_pets_section.dart';
import '../../../pet_profile/presentation/widgets/pet_card.dart';
import '../../../pet_profile/presentation/widgets/pet_list/due_events_section.dart';
import '../../../pet_profile/presentation/widgets/pet_list/pending_adoption_placements_section.dart';
import '../../../pet_profile/presentation/widgets/pet_list/pending_custody_transfers_section.dart';
import '../../../pet_profile/presentation/widgets/pet_list/pending_foster_placements_section.dart';
import '../../../pet_profile/presentation/widgets/pet_list/pending_shares_section.dart';
import '../../../pet_profile/presentation/widgets/pet_list/pet_list_section_header.dart';
import '../../../sharing/presentation/providers/sharing_providers.dart';

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
        DueEventsSection(
          pets: shellPets,
          showInlineActions: true,
        ),
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
                  child: _SharedPetDismissible(
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

class _SharedPetDismissible extends StatelessWidget {
  const _SharedPetDismissible({
    required this.pet,
    required this.l,
    required this.theme,
    required this.ref,
    required this.parentContext,
  });

  final Pet pet;
  final AppLocalizations l;
  final ThemeData theme;
  final WidgetRef ref;
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('hide_shell_shared_${pet.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.hideSharedPet),
            const SizedBox(width: 8),
            Icon(Icons.visibility_off, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: parentContext,
          builder: (ctx) => AlertDialog(
            title: Text(l.hideSharedPet),
            content: Text(l.hideSharedPetConfirm(pet.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.hide),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(hiddenSharedPetsProvider.notifier).hideSharedPet(pet.id);
          if (parentContext.mounted) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(content: Text(l.petHidden(pet.name))),
            );
          }
        }
        return false;
      },
      child: PetCard(pet: pet, onTap: () => context.go('/pet/${pet.id}')),
    );
  }
}
