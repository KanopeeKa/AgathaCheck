import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/dashboard_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../../pet_profile/presentation/widgets/pet_card.dart';
import '../../widgets/guardian_shell_shared_pet_card.dart';
import 'guardian_dashboard_helpers.dart';

/// Guardian dashboard pets: owned, fostered, and shared subgroups.
class GuardianMyPetsSection extends ConsumerWidget {
  const GuardianMyPetsSection({
    super.key,
    required this.allPets,
    required this.controller,
  });

  final List<Pet> allPets;
  final PetListController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final personalPets = guardianDashboardPersonalPets(allPets, controller);
    final fosterPets = guardianDashboardFosterPets(allPets, controller);
    final sharedPets = guardianDashboardSharedPets(allPets, controller);
    final hasAny = guardianDashboardHasAnyPets(allPets, controller);
    final showPersonalSubgroupTitle =
        personalPets.isNotEmpty &&
        (fosterPets.isNotEmpty || sharedPets.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSection(
          title: l.myPets,
          previewBuilder: (ctx) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showPersonalSubgroupTitle)
                  _PetSubgroupTitle(title: l.myPets),
                if (personalPets.isEmpty &&
                    fosterPets.isEmpty &&
                    sharedPets.isEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.noPetsYet,
                        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        key: const Key('my_pets_explore_shelters_link'),
                        onPressed: () => context.go('/o/orgs'),
                        icon: const Icon(Icons.business_outlined, size: 18),
                        label: Text(l.noPetsExploreShelters),
                      ),
                    ],
                  )
                else if (personalPets.isNotEmpty)
                  PetTileStrip(
                    useWrap: true,
                    pets: personalPets,
                    onPetTap: (pet) => context.go('/pet/${pet.id}'),
                  ),
                if (fosterPets.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _PetSubgroupTitle(title: l.myFosteredPets),
                  const SizedBox(height: 8),
                  PetTileStrip(
                    useWrap: true,
                    pets: fosterPets,
                    onPetTap: (pet) => context.go('/pet/${pet.id}'),
                  ),
                ],
                if (sharedPets.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _PetSubgroupTitle(title: l.sharedPets),
                  const SizedBox(height: 8),
                  PetTileStrip(
                    useWrap: true,
                    pets: sharedPets,
                    onPetTap: (pet) => context.go('/pet/${pet.id}'),
                    tileBuilder: (pet, tile) => GuardianShellSharedPetCard(
                      pet: pet,
                      l: l,
                      theme: theme,
                      ref: ref,
                      parentContext: context,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        if (hasAny)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('dashboard_manage_pets_link'),
              onPressed: () => context.go('/g/pets'),
              child: Text(l.managePets),
            ),
          ),
      ],
    );
  }
}

class _PetSubgroupTitle extends StatelessWidget {
  const _PetSubgroupTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
