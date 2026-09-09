import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../care_intelligence/presentation/widgets/care_safeguard_card.dart';
import '../../../care_intelligence/presentation/widgets/care_suggestion_card.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../providers/pet_care_presentation_providers.dart';
import 'care_milestone_moment_card.dart';

/// Dashboard contextual card slot (max one item across pets).
class PetCareDashboardContextualSlotSection extends ConsumerWidget {
  const PetCareDashboardContextualSlotSection({
    super.key,
    required this.pets,
    required this.petIds,
  });

  final List<Pet> pets;
  final List<String> petIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotAsync = ref.watch(petDashboardCareContextualSlotProvider(petIds));

    return slotAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (slot) {
        if (slot == null) return const SizedBox.shrink();

        return switch (slot) {
          PetCareDashboardSafeguardSlot() => CareSafeguardCard(
            petId: slot.petId,
            petName: _petName(pets, slot.petId),
            safeguard: slot.safeguard,
          ),
          PetCareDashboardSuggestionSlot() => CareSuggestionCard(
            petId: slot.petId,
            recommendation: slot.recommendation,
          ),
          PetCareDashboardMilestoneSlot() => CareMilestoneMomentCard(
            petId: slot.moment.petId,
            petName: _petName(pets, slot.moment.petId),
            moment: slot.moment,
          ),
        };
      },
    );
  }

  String _petName(List<Pet> pets, String petId) {
    return pets.where((pet) => pet.id == petId).firstOrNull?.name ?? '';
  }
}
