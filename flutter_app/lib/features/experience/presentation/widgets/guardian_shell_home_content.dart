import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../screens/guardian/guardian_my_pets_section.dart';
import '../screens/guardian/guardian_my_vets_section.dart';
import '../screens/guardian/guardian_upcoming_events_section.dart';

/// Guardian dashboard body: My Pets, Upcoming Pet Events, My Vets (phase 2.1).
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
    final shellPets = controller.guardianShellPets(allPets);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GuardianMyPetsSection(allPets: allPets, controller: controller),
          GuardianUpcomingEventsSection(pets: shellPets),
          const GuardianMyVetsSection(),
        ],
      ),
    );
  }
}
