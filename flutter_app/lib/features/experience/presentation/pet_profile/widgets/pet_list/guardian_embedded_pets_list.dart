import 'package:flutter/material.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';

import 'package:pet_profile_app/core/router/shell_return_navigation.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import '../../utils/pet_care_dashboard_helpers.dart';
import 'pet_care_pets_tile_grid.dart';
import 'guardian_passed_away_section.dart';

/// Guardian shell pets list body (`/g/pets`) with dashboard-aligned sections.
class PetCareEmbeddedPetsList extends StatelessWidget {
  const PetCareEmbeddedPetsList({
    super.key,
    required this.allPets,
    required this.controller,
    required this.careSummary,
    required this.l,
    required this.theme,
  });

  final List<Pet> allPets;
  final PetListController controller;
  final PetCareTodayCareSummary? careSummary;
  final AppLocalizations l;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final owned = petCareDashboardPersonalPets(allPets, controller);
    final carerPets = petCareDashboardCarerPets(allPets, controller);
    final passedAway = controller
        .guardianShellPets(allPets)
        .where((pet) => pet.passedAway)
        .toList();

    void openPet(Pet pet) => openPetDetail(context, pet.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (owned.isNotEmpty) ...[
          PetListSectionHeader(
            icon: Icons.person,
            title: l.myPets,
            count: owned.length,
          ),
          PetCarePetsTileGrid(
            pets: owned,
            careSummary: careSummary,
            onPetTap: openPet,
          ),
          const SizedBox(height: 16),
        ],
        if (carerPets.isNotEmpty) ...[
          PetListSectionHeader(
            icon: Icons.people_outline,
            title: l.petsImCaringFor,
            count: carerPets.length,
          ),
          PetCarePetsTileGrid(
            pets: carerPets,
            careSummary: careSummary,
            onPetTap: openPet,
          ),
          const SizedBox(height: 16),
        ],
        if (passedAway.isNotEmpty)
          PetCarePassedAwaySection(
            pets: passedAway,
            title: l.rainbowBridge,
            careSummary: careSummary,
            onPetTap: openPet,
          ),
      ],
    );
  }
}
