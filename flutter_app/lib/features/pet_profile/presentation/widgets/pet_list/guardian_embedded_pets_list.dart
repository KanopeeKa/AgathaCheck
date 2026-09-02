import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../experience/presentation/screens/guardian/guardian_dashboard_helpers.dart';
import '../../../../experience/presentation/widgets/guardian_dashboard_pet_card.dart';
import '../../../../experience/presentation/widgets/guardian_pets_tile_grid.dart';
import '../../../domain/entities/pet.dart';
import '../../controllers/pet_list_controller.dart';
import 'guardian_passed_away_section.dart';
import 'pet_list_section_header.dart';

/// Guardian shell pets list body (`/g/pets`) with dashboard-aligned sections.
class GuardianEmbeddedPetsList extends StatelessWidget {
  const GuardianEmbeddedPetsList({
    super.key,
    required this.allPets,
    required this.controller,
    required this.careSummary,
    required this.l,
    required this.theme,
  });

  final List<Pet> allPets;
  final PetListController controller;
  final GuardianTodayCareSummary? careSummary;
  final AppLocalizations l;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final owned = guardianDashboardPersonalPets(allPets, controller);
    final shared = guardianDashboardSharedPets(allPets, controller);
    final fostered = guardianDashboardFosterPets(allPets, controller);
    final passedAway =
        controller
            .guardianShellPets(allPets)
            .where((pet) => pet.passedAway)
            .toList()
          ..sort(
            (a, b) => (a.createdAt ?? DateTime(2100)).compareTo(
              b.createdAt ?? DateTime(2100),
            ),
          );

    void openPet(Pet pet) => context.go('/pet/${pet.id}');

    GuardianTodayPetCareState careFor(Pet pet) {
      if (careSummary == null) return GuardianTodayPetCareState.clear;
      return guardianTodayPetCareState(pet, careSummary!);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (owned.isNotEmpty) ...[
          PetListSectionHeader(
            icon: Icons.person,
            title: l.myPets,
            count: owned.length,
          ),
          GuardianPetsTileGrid(
            pets: owned,
            careSummary: careSummary,
            onPetTap: openPet,
          ),
          const SizedBox(height: 16),
        ],
        if (shared.isNotEmpty) ...[
          PetListSectionHeader(
            icon: Icons.people_outline,
            title: l.sharedPets,
            count: shared.length,
          ),
          GuardianPetsTileGrid(
            pets: shared,
            careSummary: careSummary,
            onPetTap: openPet,
          ),
          const SizedBox(height: 16),
        ],
        if (fostered.isNotEmpty) ...[
          PetListSectionHeader(
            icon: Icons.home_work_outlined,
            title: l.myFosteredPets,
            count: fostered.length,
          ),
          GuardianPetsTileGrid(
            pets: fostered,
            careSummary: careSummary,
            onPetTap: openPet,
          ),
          const SizedBox(height: 16),
        ],
        if (passedAway.isNotEmpty)
          GuardianPassedAwaySection(
            pets: passedAway,
            header: l.passedAway,
            cardBuilder: (pet) => GuardianDashboardPetCard(
              pet: pet,
              careState: careFor(pet),
              onTap: () => openPet(pet),
            ),
          ),
      ],
    );
  }
}
