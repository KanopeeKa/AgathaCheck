import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_intelligence/domain/entities/care_recommendation.dart';
import 'package:pet_profile_app/features/care_intelligence/presentation/providers/care_recommendations_provider.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';

CareRecommendation _pending() => const CareRecommendation(
  id: 'rec-1',
  petId: 'pet-1',
  careFamily: CareFamily.weightMonitoring,
  suggestionKey: 'weight_monitoring_rhythm',
  status: CareRecommendationStatus.pending,
  engineVersion: '1.0.0',
  knowledgeVersion: '1.0.0',
  suggestedName: 'Weight check',
  suggestedFrequency: 'monthly',
  suggestedFrequencyInterval: 1,
  rationaleKey: 'careSuggestionWeightMonitoringWhy',
);

void main() {
  test('petProfileCareSuggestionProvider surfaces first pending recommendation', () async {
    const petId = 'pet-1';
    final container = ProviderContainer(
      overrides: [
        petCareRecommendationsProvider(petId).overrideWith(
          (ref) async => [_pending()],
        ),
        petCareSafeguardsProvider(petId).overrideWith((ref) async => []),
      ],
    );
    addTearDown(container.dispose);

    await container.read(petCareRecommendationsProvider(petId).future);
    await container.read(petCareSafeguardsProvider(petId).future);

    final suggestion = container.read(petProfileCareSuggestionProvider(petId));
    expect(suggestion.isLoading, isFalse);
    expect(suggestion.hasError, isFalse);
    expect(suggestion.valueOrNull?.suggestedName, 'Weight check');
  });
}
