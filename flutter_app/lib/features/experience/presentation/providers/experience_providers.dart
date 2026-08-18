import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../organization/presentation/providers/organization_providers.dart';
import '../../../organization/domain/entities/organization.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../data/experience_preferences_store.dart';
import '../../data/guardian_onboarding_store.dart';
import '../../data/org_onboarding_store.dart';
import '../../domain/entities/app_experience.dart';
import '../../domain/services/experience_eligibility.dart';
import '../../domain/services/guardian_onboarding_rules.dart';
import '../../domain/services/organisation_section_visibility.dart';
import '../../domain/services/org_onboarding_rules.dart';

final experiencePreferencesStoreProvider = Provider<ExperiencePreferencesStore>(
  (ref) {
    return ExperiencePreferencesStore(ref.watch(sharedPreferencesProvider));
  },
);

final guardianOnboardingStoreProvider = Provider<GuardianOnboardingStore>((
  ref,
) {
  return GuardianOnboardingStore(ref.watch(sharedPreferencesProvider));
});

final guardianOnboardingCompletedProvider = Provider<bool>((ref) {
  return ref.watch(guardianOnboardingStoreProvider).readCompleted();
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

final showOrganisationSectionPrefProvider = Provider<bool>((ref) {
  return ref
      .watch(experiencePreferencesStoreProvider)
      .readShowOrganisationSection();
});

final hasOrgMembershipProvider = Provider<bool>((ref) {
  final orgs = ref.watch(organizationListProvider).valueOrNull;
  return orgs != null && orgs.isNotEmpty;
});

final showOrganisationSectionProvider = Provider<bool>((ref) {
  final pref = ref.watch(showOrganisationSectionPrefProvider);
  final hasMembership = ref.watch(hasOrgMembershipProvider);
  return OrganisationSectionVisibility.effectiveShowOrganisationSection(
    showOrganisationSectionPref: pref,
    hasOrgMembership: hasMembership,
  );
});

/// When membership appears, persist show-org on (D-v3-VIS-1).
final organisationMembershipVisibilitySyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<List<Organization>>>(organizationListProvider, (
    _,
    next,
  ) {
    next.whenData((orgs) {
      if (orgs.isNotEmpty) {
        unawaited(
          ref
              .read(experiencePreferencesStoreProvider)
              .writeShowOrganisationSection(true),
        );
        ref.invalidate(showOrganisationSectionPrefProvider);
      }
    });
  });
});

/// True when every org membership is foster-role (limited org portal).
final isFosterPortalUserProvider = Provider<bool>((ref) {
  final orgs = ref.watch(organizationListProvider).valueOrNull;
  if (orgs == null || orgs.isEmpty) return false;
  return orgs.every((o) => o.isFoster);
});

String resolvePostLoginPath({
  required ExperienceEligibility eligibility,
  bool showOrganisationSectionPref = false,
  List<Pet> pets = const [],
  List<Organization> orgs = const [],
  bool guardianOnboardingCompleted = true,
  bool orgOnboardingCompleted = true,
}) {
  final target = _resolvePostLoginExperience(
    eligibility: eligibility,
    showOrganisationSectionPref: showOrganisationSectionPref,
  );

  var path = target.homePath();
  path = GuardianOnboardingRules.resolveGuardianDestination(
    targetPath: path,
    pets: pets,
    onboardingCompleted: guardianOnboardingCompleted,
  );
  return OrgOnboardingRules.resolveOrgDestination(
    targetPath: path,
    pets: pets,
    orgs: orgs,
    onboardingCompleted: orgOnboardingCompleted,
  );
}

AppExperience _resolvePostLoginExperience({
  required ExperienceEligibility eligibility,
  required bool showOrganisationSectionPref,
}) {
  if (!eligibility.canUseGuardian && eligibility.canUseOrganization) {
    return AppExperience.organization;
  }
  return AppExperience.guardian;
}
