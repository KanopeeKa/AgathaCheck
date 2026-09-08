import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/providers/api_base_url_provider.dart';
import '../../data/datasources/care_intelligence_remote_datasource.dart';
import '../../data/repositories/care_intelligence_repository_impl.dart';
import '../../domain/entities/care_recommendation.dart';
import '../../domain/repositories/care_intelligence_repository.dart';
import '../../domain/services/pet_care_presentation_policy.dart';

final careIntelligenceRemoteDataSourceProvider =
    Provider<CareIntelligenceRemoteDataSource>((ref) {
      final baseUrl = ref.watch(apiBaseUrlProvider);
      final token = ref.watch(authProvider).accessToken;
      final ds = CareIntelligenceRemoteDataSource(baseUrl: baseUrl);
      ds.authToken = token;
      return ds;
    });

final careIntelligenceRepositoryProvider = Provider<CareIntelligenceRepository>(
  (ref) => CareIntelligenceRepositoryImpl(
    ref.watch(careIntelligenceRemoteDataSourceProvider),
  ),
);

final petCarePresentationPolicyProvider = Provider<PetCarePresentationPolicy>(
  (ref) => const PetCarePresentationPolicy(),
);

final petCareRecommendationsProvider =
    FutureProvider.family<List<CareRecommendation>, String>((ref, petId) async {
      return ref
          .read(careIntelligenceRepositoryProvider)
          .getRecommendations(petId);
    });

final petProfileCareSuggestionProvider =
    Provider.family<AsyncValue<CareRecommendation?>, String>((ref, petId) {
      final recsAsync = ref.watch(petCareRecommendationsProvider(petId));
      final policy = ref.watch(petCarePresentationPolicyProvider);
      return recsAsync.whenData((recs) => policy.profileSuggestion(recs));
    });
