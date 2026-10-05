import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/care_intelligence/care_intelligence.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import '../providers/pet_profile_care_milestone_provider.dart';

/// Profile contextual card slot: suggestion or milestone moment (safeguard is separate).
class PetProfileCareSuggestionSection extends ConsumerWidget {
  const PetProfileCareSuggestionSection({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionAsync = ref.watch(petProfileCareSuggestionProvider(petId));
    final milestoneAsync = ref.watch(petProfileCareMilestoneProvider(petId));
    final petsAsync = ref.watch(allPetsIncludingOrgProvider);
    final petName =
        petsAsync.valueOrNull
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
            petName: petName,
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
