import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/auth/auth.dart';
import '../../../../core/providers/api_base_url_provider.dart';
import '../../data/datasources/care_intelligence_remote_datasource.dart';
import '../../data/repositories/care_intelligence_repository_impl.dart';
import '../../domain/entities/care_recommendation.dart';
import '../../domain/entities/care_safeguard.dart';
import '../../domain/entities/welfare_suggestion.dart';
import '../../domain/repositories/care_intelligence_repository.dart';
import '../pet_care_presentation_policy.dart';

final petCarePresentationPolicyProvider = Provider<PetCarePresentationPolicy>(
  (ref) => const PetCarePresentationPolicy(),
);

final careIntelligenceRemoteDataSourceProvider =
    Provider<CareIntelligenceRemoteDataSource>((ref) {
      final baseUrl = ref.watch(apiBaseUrlProvider);
      final token = ref.watch(authProvider).accessToken;
      final ds = CareIntelligenceRemoteDataSource(
        baseUrl: baseUrl,
        client: ref.watch(authHttpClientProvider),
      );
      ds.authToken = token;
      return ds;
    });

final careIntelligenceRepositoryProvider = Provider<CareIntelligenceRepository>(
  (ref) => CareIntelligenceRepositoryImpl(
    ref.watch(careIntelligenceRemoteDataSourceProvider),
  ),
);

final petCareRecommendationsProvider =
    FutureProvider.family<List<CareRecommendation>, String>((ref, petId) async {
      ref.watch(authProvider.select((auth) => auth.accessToken));
      return ref
          .read(careIntelligenceRepositoryProvider)
          .getRecommendations(petId);
    });

final petWelfareSuggestionsProvider =
    FutureProvider.family<List<WelfareSuggestion>, String>((ref, petId) async {
      ref.watch(authProvider.select((auth) => auth.accessToken));
      return ref
          .read(careIntelligenceRepositoryProvider)
          .getWelfareSuggestions(petId);
    });

final petCareSafeguardsProvider =
    FutureProvider.family<List<CareSafeguard>, String>((ref, petId) async {
      ref.watch(authProvider.select((auth) => auth.accessToken));
      return ref.read(careIntelligenceRepositoryProvider).getSafeguards(petId);
    });

final petProfileCareSafeguardProvider =
    Provider.family<AsyncValue<CareSafeguard?>, String>((ref, petId) {
      final safeguardsAsync = ref.watch(petCareSafeguardsProvider(petId));
      final policy = ref.watch(petCarePresentationPolicyProvider);
      return safeguardsAsync.when(
        loading: () => const AsyncLoading(),
        error: (error, stackTrace) =>
            AsyncError(error, stackTrace ?? StackTrace.empty),
        data: (safeguards) => AsyncData(policy.profileSafeguard(safeguards)),
      );
    });

final petProfileCareSuggestionProvider =
    Provider.family<AsyncValue<CareRecommendation?>, String>((ref, petId) {
      final recsAsync = ref.watch(petCareRecommendationsProvider(petId));
      final welfareAsync = ref.watch(petWelfareSuggestionsProvider(petId));
      final safeguardAsync = ref.watch(petProfileCareSafeguardProvider(petId));
      final policy = ref.watch(petCarePresentationPolicyProvider);

      if (recsAsync.isLoading ||
          safeguardAsync.isLoading ||
          welfareAsync.isLoading) {
        return const AsyncLoading();
      }
      if (recsAsync.hasError) {
        return AsyncError(
          recsAsync.error!,
          recsAsync.stackTrace ?? StackTrace.empty,
        );
      }
      if (safeguardAsync.hasError) {
        return AsyncError(
          safeguardAsync.error!,
          safeguardAsync.stackTrace ?? StackTrace.empty,
        );
      }
      if (welfareAsync.hasError) {
        return AsyncError(
          welfareAsync.error!,
          welfareAsync.stackTrace ?? StackTrace.empty,
        );
      }

      return AsyncData(
        policy.profileSuggestion(
          recsAsync.value ?? const [],
          activeSafeguard: safeguardAsync.valueOrNull,
          welfareSuggestions: welfareAsync.value ?? const [],
        ),
      );
    });

final petProfileWelfareSuggestionProvider =
    Provider.family<AsyncValue<WelfareSuggestion?>, String>((ref, petId) {
      final recsAsync = ref.watch(petCareRecommendationsProvider(petId));
      final welfareAsync = ref.watch(petWelfareSuggestionsProvider(petId));
      final safeguardAsync = ref.watch(petProfileCareSafeguardProvider(petId));
      final policy = ref.watch(petCarePresentationPolicyProvider);

      if (recsAsync.isLoading ||
          safeguardAsync.isLoading ||
          welfareAsync.isLoading) {
        return const AsyncLoading();
      }
      if (recsAsync.hasError) {
        return AsyncError(
          recsAsync.error!,
          recsAsync.stackTrace ?? StackTrace.empty,
        );
      }
      if (safeguardAsync.hasError) {
        return AsyncError(
          safeguardAsync.error!,
          safeguardAsync.stackTrace ?? StackTrace.empty,
        );
      }
      if (welfareAsync.hasError) {
        return AsyncError(
          welfareAsync.error!,
          welfareAsync.stackTrace ?? StackTrace.empty,
        );
      }

      return AsyncData(
        policy.profileWelfareSuggestion(
          welfareAsync.value ?? const [],
          recsAsync.value ?? const [],
          activeSafeguard: safeguardAsync.valueOrNull,
        ),
      );
    });
