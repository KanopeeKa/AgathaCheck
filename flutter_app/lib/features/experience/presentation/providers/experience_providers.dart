import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../organization/presentation/providers/organization_providers.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../data/experience_preferences_store.dart';
import '../../domain/entities/app_experience.dart';
import '../../domain/services/experience_eligibility.dart';

final experiencePreferencesStoreProvider = Provider<ExperiencePreferencesStore>((
  ref,
) {
  return ExperiencePreferencesStore(ref.watch(sharedPreferencesProvider));
});

final experienceEligibilityProvider = Provider<AsyncValue<ExperienceEligibility>>(
  (ref) {
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
  },
);

final savedDefaultExperienceProvider = Provider<AppExperience?>((ref) {
  return ref.watch(experiencePreferencesStoreProvider).readDefaultExperience();
});

final activeExperienceProvider = StateProvider<AppExperience?>((ref) => null);

String resolvePostLoginPath({
  required ExperienceEligibility eligibility,
  AppExperience? savedDefault,
  AppExperience? activeExperience,
}) {
  if (activeExperience != null &&
      eligibility.availableExperiences.contains(activeExperience)) {
    return activeExperience.homePath();
  }
  final auto = eligibility.resolveAutoExperience(savedDefault: savedDefault);
  if (auto != null) return auto.homePath();
  return '/app/choose';
}
