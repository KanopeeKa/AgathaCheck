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

final savedDefaultExperienceProvider = Provider<AppExperience?>((ref) {
  return ref.watch(experiencePreferencesStoreProvider).readDefaultExperience();
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

final lastAppSectionProvider = Provider<AppExperience?>((ref) {
  return ref.watch(experiencePreferencesStoreProvider).readLastAppSection();
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

final activeExperienceProvider = StateProvider<AppExperience?>((ref) => null);

/// Home path for the user's current experience (active → last section → guardian).
final experienceHomePathProvider = Provider<String>((ref) {
  final active = ref.watch(activeExperienceProvider);
  if (active != null) return active.homePath();

  final lastSection = ref.watch(lastAppSectionProvider);
  if (lastSection != null) return lastSection.homePath();

  final eligibility = ref.watch(experienceEligibilityProvider).valueOrNull;
  final showOrgPref = ref.watch(showOrganisationSectionPrefProvider);
  final resolved = _resolveSectionForRouting(
    eligibility: eligibility,
    section: lastSection,
    showOrganisationSectionPref: showOrgPref,
  );
  return resolved?.homePath() ?? AppExperience.guardian.homePath();
});

/// True when every org membership is foster-role (limited org portal).
final isFosterPortalUserProvider = Provider<bool>((ref) {
  final orgs = ref.watch(organizationListProvider).valueOrNull;
  if (orgs == null || orgs.isEmpty) return false;
  return orgs.every((o) => o.isFoster);
});

/// Resolved experience for pet-detail and other cross-route context.
final resolvedExperienceProvider = Provider<AppExperience>((ref) {
  return ref.watch(activeExperienceProvider) ??
      ref.watch(savedDefaultExperienceProvider) ??
      AppExperience.guardian;
});

String resolvePostLoginPath({
  required ExperienceEligibility eligibility,
  AppExperience? lastAppSection,
  AppExperience? activeExperience,
  bool showOrganisationSectionPref = false,
  List<Pet> pets = const [],
  List<Organization> orgs = const [],
  bool guardianOnboardingCompleted = true,
  bool orgOnboardingCompleted = true,
}) {
  final target = _resolvePostLoginExperience(
    eligibility: eligibility,
    lastAppSection: lastAppSection,
    activeExperience: activeExperience,
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
  AppExperience? lastAppSection,
  AppExperience? activeExperience,
  required bool showOrganisationSectionPref,
}) {
  AppExperience? pick(AppExperience section) {
    if (section == AppExperience.guardian && eligibility.canUseGuardian) {
      return section;
    }
    if (section == AppExperience.organization &&
        OrganisationSectionVisibility.canAccessOrganizationSection(
          hasOrgMembership: eligibility.hasOrgMembership,
          showOrganisationSectionPref: showOrganisationSectionPref,
        )) {
      return section;
    }
    return null;
  }

  if (activeExperience != null) {
    final resolved = pick(activeExperience);
    if (resolved != null) return resolved;
  }

  if (lastAppSection != null) {
    final resolved = pick(lastAppSection);
    if (resolved != null) return resolved;
  }

  return _fallbackPostLoginExperience(
    eligibility: eligibility,
    showOrganisationSectionPref: showOrganisationSectionPref,
  );
}

AppExperience _fallbackPostLoginExperience({
  required ExperienceEligibility eligibility,
  required bool showOrganisationSectionPref,
}) {
  if (!eligibility.canUseGuardian && eligibility.canUseOrganization) {
    return AppExperience.organization;
  }
  return AppExperience.guardian;
}

AppExperience? _resolveSectionForRouting({
  required ExperienceEligibility? eligibility,
  required AppExperience? section,
  required bool showOrganisationSectionPref,
}) {
  if (eligibility == null || section == null) return null;
  if (section == AppExperience.guardian && eligibility.canUseGuardian) {
    return section;
  }
  if (section == AppExperience.organization &&
      OrganisationSectionVisibility.canAccessOrganizationSection(
        hasOrgMembership: eligibility.hasOrgMembership,
        showOrganisationSectionPref: showOrganisationSectionPref,
      )) {
    return section;
  }
  return null;
}
