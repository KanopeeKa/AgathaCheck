import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/features/care_intelligence/care_intelligence.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';

import '../../profile_completeness_for_pet.dart';
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
    final slotPolicy = ref.watch(petCarePresentationPolicyProvider);
    const surfacePolicy = AgathaSurfacePolicy();
    final storeAsync = ref.watch(profileCompletenessDismissalStoreProvider);
    final safeguard = ref
        .watch(petProfileCareSafeguardProvider(pet.id))
        .valueOrNull;
    final suggestion = ref
        .watch(petProfileCareSuggestionProvider(pet.id))
        .valueOrNull;
    final welfare = ref
        .watch(petProfileWelfareSuggestionProvider(pet.id))
        .valueOrNull;
    final milestone = ref
        .watch(petProfileCareMilestoneProvider(pet.id))
        .valueOrNull;
    final guidanceMomentVisible = suggestion != null || milestone != null;

    if (!slotPolicy.profileCompletenessSlotAvailable(
      activeSafeguard: safeguard,
      activeSuggestion: suggestion,
      activeWelfareSuggestion: welfare,
      guidanceMomentVisible: guidanceMomentVisible,
    )) {
      return const SizedBox.shrink();
    }

    return storeAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (store) {
        final now = DateTime.now().toUtc();
        final kinds = profileCompletenessKindsForPet(
          pet,
          policy: surfacePolicy,
          now: now,
          neuterDismissedAt: store.dismissedAt(
            pet.id,
            ProfileCompletenessKind.neuter,
          ),
          chipDismissedAt: store.dismissedAt(
            pet.id,
            ProfileCompletenessKind.chip,
          ),
        );
        if (kinds.isEmpty) return const SizedBox.shrink();

        final canRecord = viewerContext.can(PetDetailAction.editProfile);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final kind in kinds)
              ProfileCompletenessCard(
                pet: pet,
                kind: kind,
                canRecord: canRecord,
              ),
          ],
        );
      },
    );
  }
}
