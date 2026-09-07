import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../data/experience_preferences_store.dart';
import '../../data/pet_care_onboarding_store.dart';
import '../../data/org_onboarding_store.dart';
import '../../domain/entities/app_experience.dart';
import '../../domain/services/experience_eligibility.dart';
import '../../domain/services/pet_care_onboarding_rules.dart';

final experiencePreferencesStoreProvider = Provider<ExperiencePreferencesStore>(
  (ref) {
    return ExperiencePreferencesStore(ref.watch(sharedPreferencesProvider));
  },
);

final petCareOnboardingStoreProvider = Provider<PetCareOnboardingStore>((ref) {
  return PetCareOnboardingStore(ref.watch(sharedPreferencesProvider));
});

final petCareOnboardingCompletedProvider = Provider<bool>((ref) {
  return ref.watch(petCareOnboardingStoreProvider).readCompleted();
});

final orgOnboardingStoreProvider = Provider<OrgOnboardingStore>((ref) {
  return OrgOnboardingStore(ref.watch(sharedPreferencesProvider));
});

final orgOnboardingCompletedProvider = Provider<bool>((ref) {
  return ref.watch(orgOnboardingStoreProvider).readCompleted();
});

final experienceEligibilityProvider =
    Provider<AsyncValue<ExperienceEligibility>>((ref) {
      final petsAsync = ref.watch(petListProvider);

      return petsAsync.when(
        data: (pets) => AsyncValue.data(
          ExperienceEligibilityRules.compute(pets: pets, orgMembershipCount: 0),
        ),
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    });

final hasOrgMembershipProvider = Provider<bool>((ref) => false);

/// Frozen MVP: foster portal is not reachable.
final isFosterPortalUserProvider = Provider<bool>((ref) => false);

/// True when the user has no pets and should pick a path.
bool needsFirstTimeExperience({
  required List<Pet> pets,
  bool hasPendingOrgInvites = false,
}) {
  return pets.isEmpty && !hasPendingOrgInvites;
}

String resolvePostLoginPath({
  required ExperienceEligibility eligibility,
  List<Pet> pets = const [],
  bool petCareOnboardingCompleted = true,
  bool orgOnboardingCompleted = true,
  bool hasPendingOrgInvites = false,
}) {
  var path = AppExperience.petCare.homePath();
  path = PetCareOnboardingRules.resolvePetCareDestination(
    targetPath: path,
    pets: pets,
    onboardingCompleted: petCareOnboardingCompleted,
  );
  return path;
}
