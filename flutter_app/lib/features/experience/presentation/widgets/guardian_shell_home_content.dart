import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../screens/guardian/guardian_my_pets_section.dart';
import '../screens/guardian/guardian_my_vets_section.dart';
import '../screens/guardian/guardian_upcoming_events_section.dart';
import 'guardian_operations_desk_layout.dart';

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
    final baseTheme = Theme.of(context);
    final deskTheme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: AppColorTokens.guardianCarePrimary,
        onPrimary: AppColorTokens.inverse,
        primaryContainer: AppColorTokens.guardianCareLight,
        onPrimaryContainer: AppColorTokens.guardianCareActive,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorTokens.guardianCarePrimary,
          minimumSize: const Size(48, 48),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Theme(
          data: deskTheme,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: GuardianOperationsDeskLayout(
              useWideLayout:
                  constraints.maxWidth >=
                  GuardianOperationsDeskLayout.wideBreakpoint,
              petsSection: GuardianMyPetsSection(
                allPets: allPets,
                controller: controller,
              ),
              eventsSection: GuardianUpcomingEventsSection(pets: shellPets),
              vetsSection: const GuardianMyVetsSection(),
            ),
          ),
        );
      },
    );
  }
}
