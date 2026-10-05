import 'package:flutter/material.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';

import 'package:pet_profile_app/features/care_intelligence/care_intelligence.dart';
import 'package:pet_profile_app/features/pet_tags/pet_tags.dart';
import '../pet_care_section/pet_care_section.dart';
import 'pet_detail_profile_card.dart';
import 'pet_profile_completeness_prompt.dart';
import 'pet_profile_health_history_section.dart';
import 'pet_profile_weight_insight_section.dart';

/// Scrollable pet profile body in spec §9 order, with desktop sidebar for insight rows.
class PetDetailScrollBody extends StatelessWidget {
  const PetDetailScrollBody({
    super.key,
    required this.pet,
    required this.viewerContext,
  });

  final Pet pet;
  final PetDetailContext viewerContext;

  static const double _desktopBreakpoint = PetFormBreakpoints.desktopMin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSidebar = constraints.maxWidth >= _desktopBreakpoint;

        final primaryColumn = <Widget>[
          PetDetailProfileCard(pet: pet, viewerContext: viewerContext),
          PetProfileCompletenessPrompt(pet: pet),
          PetProfileCareSafeguardSection(petId: pet.id, petName: pet.name),
          PetCareSection(petId: pet.id, pet: pet),
          PetProfileCareSuggestionSection(petId: pet.id),
          PetTagChipRow(petId: pet.id),
        ];

        final secondaryColumn = <Widget>[
          PetProfileWeightInsightSection(petId: pet.id, pet: pet),
          PetProfileHealthHistorySection(petId: pet.id),
        ];

        if (!useSidebar) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...primaryColumn,
              ...secondaryColumn,
              const SizedBox(height: 32),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: primaryColumn,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [...secondaryColumn, const SizedBox(height: 32)],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
