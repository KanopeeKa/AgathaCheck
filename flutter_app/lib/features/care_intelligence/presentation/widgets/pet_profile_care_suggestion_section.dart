import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../providers/care_recommendations_provider.dart';
import '../../../pet_care/presentation/providers/pet_care_presentation_providers.dart';
import '../../../pet_care/presentation/widgets/care_milestone_moment_card.dart';
import 'care_suggestion_card.dart';

/// Profile contextual card slot: suggestion or milestone moment (safeguard is separate).
class PetProfileCareSuggestionSection extends ConsumerWidget {
  const PetProfileCareSuggestionSection({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionAsync = ref.watch(petProfileCareSuggestionProvider(petId));
    final milestoneAsync = ref.watch(petProfileCareMilestoneProvider(petId));
    final petsAsync = ref.watch(allPetsIncludingOrgProvider);
    final petName = petsAsync.valueOrNull
            ?.where((pet) => pet.id == petId)
            .firstOrNull
            ?.name ??
        '';

    return suggestionAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (recommendation) {
        if (recommendation != null) {
          return CareSuggestionCard(
            petId: petId,
            recommendation: recommendation,
          );
        }

        return milestoneAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (moment) {
            if (moment == null) return const SizedBox.shrink();
            return CareMilestoneMomentCard(
              petId: petId,
              petName: petName,
              moment: moment,
            );
          },
        );
      },
    );
  }
}
