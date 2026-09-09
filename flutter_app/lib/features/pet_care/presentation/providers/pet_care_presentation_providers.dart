import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/providers/api_base_url_provider.dart';
import '../../../care_intelligence/domain/entities/care_recommendation.dart';
import '../../../care_intelligence/domain/entities/care_safeguard.dart';
import '../../../care_intelligence/presentation/providers/care_recommendations_provider.dart';
import '../../progression/data/datasources/care_progression_moments_remote_datasource.dart';
import '../../progression/data/repositories/care_progression_moments_repository_impl.dart';
import '../../progression/domain/entities/care_pending_moment.dart';
import '../../progression/domain/repositories/care_progression_moments_repository.dart';
import '../pet_care_presentation_policy.dart';

export '../pet_care_presentation_policy.dart';

final petCarePresentationPolicyProvider = Provider<PetCarePresentationPolicy>(
  (ref) => const PetCarePresentationPolicy(),
);

final careProgressionMomentsRemoteDataSourceProvider =
    Provider<CareProgressionMomentsRemoteDataSource>((ref) {
      final baseUrl = ref.watch(apiBaseUrlProvider);
      final token = ref.watch(authProvider).accessToken;
      final ds = CareProgressionMomentsRemoteDataSource(
        baseUrl: baseUrl,
        client: ref.watch(authHttpClientProvider),
      );
      ds.authToken = token;
      return ds;
    });

final careProgressionMomentsRepositoryProvider =
    Provider<CareProgressionMomentsRepository>(
      (ref) => CareProgressionMomentsRepositoryImpl(
        ref.watch(careProgressionMomentsRemoteDataSourceProvider),
      ),
    );

final petPendingCareMomentsProvider =
    FutureProvider.family<CarePendingMomentsResponse, String>((
      ref,
      petId,
    ) async {
      return ref
          .read(careProgressionMomentsRepositoryProvider)
          .getPendingMoments(petId);
    });

final petProfileCareMilestoneProvider =
    Provider.family<AsyncValue<CarePendingMoment?>, String>((ref, petId) {
      final policy = ref.watch(petCarePresentationPolicyProvider);
      final safeguardAsync = ref.watch(petProfileCareSafeguardProvider(petId));
      final suggestionAsync = ref.watch(
        petProfileCareSuggestionProvider(petId),
      );
      final momentsAsync = ref.watch(petPendingCareMomentsProvider(petId));

      if (momentsAsync.isLoading ||
          safeguardAsync.isLoading ||
          suggestionAsync.isLoading) {
        return const AsyncLoading();
      }
      if (momentsAsync.hasError) {
        return AsyncError(
          momentsAsync.error!,
          momentsAsync.stackTrace ?? StackTrace.empty,
        );
      }

      final moment = momentsAsync.valueOrNull?.moments.firstOrNull;
      return AsyncData(
        policy.profileMilestoneMoment(
          moment,
          activeSafeguard: safeguardAsync.valueOrNull,
          activeSuggestion: suggestionAsync.valueOrNull,
        ),
      );
    });

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
        return AsyncError(error!, stackTrace ?? StackTrace.empty);
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

      final moment = policy.dashboardMilestoneMoment(
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
