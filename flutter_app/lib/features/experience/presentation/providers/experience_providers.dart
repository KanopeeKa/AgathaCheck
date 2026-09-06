import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../organization/presentation/providers/organization_providers.dart';
import '../../../organization/domain/entities/organization.dart';
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
      final orgsAsync = ref.watch(organizationListProvider);

      return petsAsync.when(
        data: (pets) => orgsAsync.when(
          data: (orgs) => AsyncValue.data(
            ExperienceEligibilityRules.compute(
              pets: pets,
              orgMembershipCount: orgs.length,
            ),
          ),
          loading: () => const AsyncValue.loading(),
          error: (e, st) => AsyncValue.error(e, st),
        ),
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    });

final hasOrgMembershipProvider = Provider<bool>((ref) {
  final orgs = ref.watch(organizationListProvider).valueOrNull;
  return orgs != null && orgs.isNotEmpty;
});

/// True when every org membership is foster-role (limited org portal).
final isFosterPortalUserProvider = Provider<bool>((ref) {
  final orgs = ref.watch(organizationListProvider).valueOrNull;
  if (orgs == null || orgs.isEmpty) return false;
  return orgs.every((o) => o.isFoster);
});

/// True when the user has no pets or shelter memberships and should pick a path.
bool needsFirstTimeExperience({
  required List<Pet> pets,
  required List<Organization> orgs,
  bool hasPendingOrgInvites = false,
}) {
  return pets.isEmpty && orgs.isEmpty && !hasPendingOrgInvites;
}

String resolvePostLoginPath({
  required ExperienceEligibility eligibility,
  List<Pet> pets = const [],
  List<Organization> orgs = const [],
  bool petCareOnboardingCompleted = true,
  bool orgOnboardingCompleted = true,
  bool hasPendingOrgInvites = false,
}) {
  // D-v5-WORKSPACE-2: everyone lands on Pet Care home (empty state when no pets).
  var path = AppExperience.petCare.homePath();
  path = PetCareOnboardingRules.resolvePetCareDestination(
    targetPath: path,
    pets: pets,
    onboardingCompleted: petCareOnboardingCompleted,
  );
  return path;
}
