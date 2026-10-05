import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/care_intelligence/care_intelligence.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';

sealed class PetCareDashboardContextualSlot {}

class PetCareDashboardSafeguardSlot extends PetCareDashboardContextualSlot {
  PetCareDashboardSafeguardSlot({
    required this.petId,
    required this.petName,
    required this.safeguard,
  });

  final String petId;
  final String petName;
  final CareSafeguard safeguard;
}

class PetCareDashboardSuggestionSlot extends PetCareDashboardContextualSlot {
  PetCareDashboardSuggestionSlot({
    required this.petId,
    required this.recommendation,
  });

  final String petId;
  final CareRecommendation recommendation;
}

class PetCareDashboardMilestoneSlot extends PetCareDashboardContextualSlot {
  PetCareDashboardMilestoneSlot({required this.petName, required this.moment});

  final String petName;
  final CarePendingMoment moment;
}

CarePendingMoment? _dashboardMilestoneMoment(
  Map<String, CarePendingMoment?> momentsByPetId, {
  CareSafeguard? activeSafeguard,
  CareRecommendation? activeSuggestion,
}) {
  if (activeSafeguard != null || activeSuggestion != null) return null;
  for (final moment in momentsByPetId.values) {
    if (moment != null) return moment;
  }
  return null;
}

final petDashboardCareContextualSlotProvider =
    Provider.family<AsyncValue<PetCareDashboardContextualSlot?>, List<String>>((
      ref,
      petIds,
    ) {
      if (petIds.isEmpty) return const AsyncData(null);

      final policy = ref.watch(petCarePresentationPolicyProvider);
      final safeguardsByPetId = <String, List<CareSafeguard>>{};
      final recommendationsByPetId = <String, List<CareRecommendation>>{};
      final momentsByPetId = <String, CarePendingMoment?>{};
      var loading = false;
      Object? error;
      StackTrace? stackTrace;

      for (final petId in petIds) {
        final safeguardsAsync = ref.watch(petCareSafeguardsProvider(petId));
        final recommendationsAsync = ref.watch(
          petCareRecommendationsProvider(petId),
        );
        final momentsAsync = ref.watch(petPendingCareMomentsProvider(petId));

        if (safeguardsAsync.isLoading ||
            recommendationsAsync.isLoading ||
            momentsAsync.isLoading) {
          loading = true;
        }
        if (momentsAsync.hasError && error == null) {
          error = momentsAsync.error;
          stackTrace = momentsAsync.stackTrace;
        }

        safeguardsByPetId[petId] = safeguardsAsync.valueOrNull ?? const [];
        recommendationsByPetId[petId] =
            recommendationsAsync.valueOrNull ?? const [];
        momentsByPetId[petId] = momentsAsync.valueOrNull?.moments.firstOrNull;
      }

      if (loading) return const AsyncLoading();
      if (error != null) {
        return AsyncError(error, stackTrace ?? StackTrace.empty);
      }

      final activeSafeguard = policy.dashboardSafeguard(safeguardsByPetId);
      if (activeSafeguard != null) {
        return AsyncData(
          PetCareDashboardSafeguardSlot(
            petId: activeSafeguard.petId,
            petName: '',
            safeguard: activeSafeguard,
          ),
        );
      }

      final suggestion = policy.dashboardSuggestion(
        recommendationsByPetId,
        activeSafeguard: activeSafeguard,
      );
      if (suggestion != null) {
        return AsyncData(
          PetCareDashboardSuggestionSlot(
            petId: suggestion.petId,
            recommendation: suggestion,
          ),
        );
      }

      final moment = _dashboardMilestoneMoment(
        momentsByPetId,
        activeSafeguard: activeSafeguard,
        activeSuggestion: suggestion,
      );
      if (moment != null) {
        return AsyncData(
          PetCareDashboardMilestoneSlot(petName: '', moment: moment),
        );
      }

      return const AsyncData(null);
    });
