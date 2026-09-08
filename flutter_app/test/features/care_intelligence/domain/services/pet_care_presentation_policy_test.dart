import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/care_intelligence/domain/entities/care_recommendation.dart';
import 'package:pet_profile_app/features/care_intelligence/domain/services/pet_care_presentation_policy.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';

CareRecommendation _rec({
  required String id,
  CareRecommendationStatus status = CareRecommendationStatus.pending,
}) {
  return CareRecommendation(
    id: id,
    petId: 'pet-1',
    careFamily: CareFamily.wellnessReview,
    suggestionKey: 'wellness_review_rhythm',
    status: status,
    engineVersion: '1.0.0',
    knowledgeVersion: '1.0.0',
    suggestedName: 'Wellness review',
    suggestedFrequency: 'yearly',
    suggestedFrequencyInterval: 1,
    suggestedHealthEntryType: 'vet_visit',
    rationaleKey: 'careSuggestionWellnessWhy',
  );
}

void main() {
  const policy = PetCarePresentationPolicy();

  test('profileSuggestion returns first pending only', () {
    final rec = policy.profileSuggestion([
      _rec(id: 'dismissed', status: CareRecommendationStatus.dismissed),
      _rec(id: 'pending'),
    ]);
    expect(rec?.id, 'pending');
  });

  test('dashboardSuggestion returns at most one pending across pets', () {
    final rec = policy.dashboardSuggestion({
      'pet-1': [_rec(id: 'a', status: CareRecommendationStatus.dismissed)],
      'pet-2': [_rec(id: 'b')],
      'pet-3': [_rec(id: 'c')],
    });
    expect(rec?.id, 'b');
  });
}
