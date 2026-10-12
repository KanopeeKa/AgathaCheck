import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/care_intelligence/domain/entities/care_recommendation.dart';
import 'package:pet_profile_app/features/care_intelligence/domain/entities/care_safeguard.dart';
import 'package:pet_profile_app/features/care_intelligence/presentation/agatha_surface_policy.dart';
import 'package:pet_profile_app/features/care_intelligence/presentation/pet_care_presentation_policy.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';

CareRecommendation _rec({
  required String id,
  String petId = 'pet-1',
  CareRecommendationStatus status = CareRecommendationStatus.pending,
  DateTime? respondedAt,
}) {
  return CareRecommendation(
    id: id,
    petId: petId,
    careFamily: CareFamily.wellnessReview,
    suggestionKey: 'wellness_review_rhythm',
    status: status,
    engineVersion: '1.0.0',
    knowledgeVersion: '1.0.0',
    suggestedName: 'Wellness review',
    suggestedFrequency: 'yearly',
    suggestedFrequencyInterval: 1,
    rationaleKey: 'careSuggestionWellnessWhy',
    respondedAt: respondedAt,
  );
}

CareSafeguard _safeguard({
  required String id,
  String petId = 'pet-1',
  String status = 'active',
}) {
  return CareSafeguard(
    id: id,
    petId: petId,
    safeguardType: 'weight_trend_down',
    safeguardKey: 'weight_trend_down:$petId',
    status: status,
    policyVersion: '1.0.0',
    copyKey: 'careSafeguardWeightTrendDown',
    evidence: const {'measurement_count': 4},
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

  test('AC-SP-01 profileSuggestion suppressed when safeguard active', () {
    final rec = policy.profileSuggestion([
      _rec(id: 'pending'),
    ], activeSafeguard: _safeguard(id: 'sg-1'));
    expect(rec, isNull);
  });

  test('AC-SP-01 profileSuggestion picks rhythm over welfare candidate', () {
    final rec = policy.profileSuggestion(
      [_rec(id: 'rhythm-pending')],
      welfareCandidates: [
        AgathaGuidanceCandidate(
          kind: AgathaGuidanceKind.welfare,
          severity: 50,
          createdAt: DateTime.utc(2020, 1, 1),
          id: 'welfare-1',
        ),
      ],
    );
    expect(rec?.id, 'rhythm-pending');
  });

  test('dashboardSuggestion returns oldest pending rhythm across pets', () {
    final rec = policy.dashboardSuggestion({
      'pet-1': [_rec(id: 'a', status: CareRecommendationStatus.dismissed)],
      'pet-2': [
        _rec(
          id: 'newer',
          petId: 'pet-2',
          respondedAt: DateTime.utc(2025, 1, 1),
        ),
      ],
      'pet-3': [
        _rec(
          id: 'older',
          petId: 'pet-3',
          respondedAt: DateTime.utc(2024, 1, 1),
        ),
      ],
    });
    expect(rec?.id, 'older');
  });

  test('dashboardSuggestion suppressed when safeguard active', () {
    final rec = policy.dashboardSuggestion({
      'pet-2': [_rec(id: 'b')],
    }, activeSafeguard: _safeguard(id: 'sg-1'));
    expect(rec, isNull);
  });

  test('dashboardSafeguard suppresses dashboard suggestion', () {
    final safeguard = policy.dashboardSafeguard({
      'pet-2': [_safeguard(id: 'sg-2', petId: 'pet-2')],
    });
    expect(safeguard?.id, 'sg-2');

    final suggestion = policy.dashboardSuggestion({
      'pet-1': [_rec(id: 'pending')],
    }, activeSafeguard: safeguard);
    expect(suggestion, isNull);
  });

  test('profileSafeguard returns first active safeguard', () {
    final safeguard = policy.profileSafeguard([
      _safeguard(id: 'sg-1'),
      _safeguard(id: 'sg-2'),
    ]);
    expect(safeguard?.id, 'sg-1');
  });

  test('profileSafeguard ignores dismissed safeguards', () {
    final safeguard = policy.profileSafeguard([
      _safeguard(id: 'sg-1', status: 'dismissed'),
      _safeguard(id: 'sg-2'),
    ]);
    expect(safeguard?.id, 'sg-2');
  });

  test('profileSafeguard returns null when all dismissed', () {
    final safeguard = policy.profileSafeguard([
      _safeguard(id: 'sg-1', status: 'dismissed'),
      _safeguard(id: 'sg-2', status: 'dismissed'),
    ]);
    expect(safeguard, isNull);
  });

  test('profileSafeguard returns null for empty list', () {
    expect(policy.profileSafeguard([]), isNull);
  });

  test('dashboardSafeguard ignores dismissed and returns first active', () {
    final safeguard = policy.dashboardSafeguard({
      'pet-1': [_safeguard(id: 'sg-1', petId: 'pet-1', status: 'dismissed')],
      'pet-2': [_safeguard(id: 'sg-2', petId: 'pet-2')],
    });
    expect(safeguard?.id, 'sg-2');
  });

  test('profileCompletenessSlotAvailable false when suggestion active', () {
    expect(
      policy.profileCompletenessSlotAvailable(
        activeSuggestion: _rec(id: 'pending'),
        guidanceMomentVisible: false,
      ),
      isFalse,
    );
  });

  test('profileCompletenessSlotAvailable false when milestone visible', () {
    expect(
      policy.profileCompletenessSlotAvailable(guidanceMomentVisible: true),
      isFalse,
    );
  });

  test('dashboardSafeguard returns null when no active safeguard exists', () {
    final safeguard = policy.dashboardSafeguard({
      'pet-1': [_safeguard(id: 'sg-1', status: 'dismissed')],
      'pet-2': [_safeguard(id: 'sg-2', status: 'dismissed')],
    });
    expect(safeguard, isNull);
  });
}
