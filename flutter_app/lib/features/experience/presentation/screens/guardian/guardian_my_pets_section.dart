import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/dashboard_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../../pet_profile/presentation/widgets/pet_card.dart';
import 'guardian_dashboard_helpers.dart';

/// Guardian dashboard pets: My pets + My foster pets tile strips.
class GuardianMyPetsSection extends StatelessWidget {
  const GuardianMyPetsSection({
    super.key,
    required this.allPets,
    required this.controller,
  });

  final List<Pet> allPets;
  final PetListController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final personalPets = guardianDashboardPersonalPets(allPets, controller);
    final fosterPets = guardianDashboardFosterPets(allPets, controller);
    final hasAny = guardianDashboardHasAnyPets(allPets, controller);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSection(
          title: l.myPets,
          previewBuilder: (ctx) {
            if (personalPets.isEmpty) {
              return Text(
                l.noPetsYet,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              );
            }
            return PetTileStrip(
              pets: personalPets,
              onPetTap: (pet) => context.go('/pet/${pet.id}'),
            );
          },
        ),
        if (fosterPets.isNotEmpty)
          DashboardSection(
            title: l.myFosteredPets,
            previewBuilder: (ctx) {
              return PetTileStrip(
                pets: fosterPets,
                onPetTap: (pet) => context.go('/pet/${pet.id}'),
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
