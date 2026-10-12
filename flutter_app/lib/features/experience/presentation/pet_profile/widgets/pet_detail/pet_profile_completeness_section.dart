import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/features/care_intelligence/care_intelligence.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';

import '../../providers/pet_profile_care_milestone_provider.dart';

/// Agatha completeness cards (PR-04); hidden when guidance slot is taken.
class PetProfileCompletenessSection extends ConsumerWidget {
  const PetProfileCompletenessSection({
    super.key,
    required this.pet,
    required this.viewerContext,
  });

  final Pet pet;
  final PetDetailContext viewerContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(petCarePresentationPolicyProvider);
    final safeguard = ref
        .watch(petProfileCareSafeguardProvider(pet.id))
        .valueOrNull;
    final suggestion = ref
        .watch(petProfileCareSuggestionProvider(pet.id))
        .valueOrNull;
    final milestone = ref
        .watch(petProfileCareMilestoneProvider(pet.id))
        .valueOrNull;
    final guidanceMomentVisible = suggestion != null || milestone != null;

    if (!policy.profileCompletenessSlotAvailable(
      activeSafeguard: safeguard,
      activeSuggestion: suggestion,
      guidanceMomentVisible: guidanceMomentVisible,
    )) {
      return const SizedBox.shrink();
    }

    final kinds = policy.profileCompletenessCandidates(pet);
    if (kinds.isEmpty) return const SizedBox.shrink();

    final canRecord = viewerContext.can(PetDetailAction.editProfile);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final kind in kinds)
          ProfileCompletenessCard(pet: pet, kind: kind, canRecord: canRecord),
      ],
    );
  }
}
