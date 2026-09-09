import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/care_intelligence/domain/entities/care_recommendation.dart';
import 'package:pet_profile_app/features/care_intelligence/domain/entities/care_safeguard.dart';
import 'package:pet_profile_app/features/pet_care/presentation/pet_care_presentation_policy.dart';
import 'package:pet_profile_app/features/pet_care/progression/domain/entities/care_pending_moment.dart';
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

CareSafeguard _safeguard({required String id, String petId = 'pet-1'}) {
  return CareSafeguard(
    id: id,
    petId: petId,
    safeguardType: 'weight_trend_down',
    safeguardKey: 'weight_trend_down:$petId',
    status: 'active',
    policyVersion: '1.0.0',
    copyKey: 'careSafeguardWeightTrendDown',
    evidence: const {'measurement_count': 4},
  );
}

CarePendingMoment _moment({
  required String petId,
  String bundleId = 'bundle-1',
  bool includesFirstCare = false,
}) {
  return CarePendingMoment(
    petId: petId,
    bundleId: bundleId,
    primaryMilestoneType: 'weight_monitoring_established',
    includesFirstCare: includesFirstCare,
    achievedAt: DateTime.utc(2026, 9, 9),
    milestones: const [],
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

  test('profileSuggestion suppressed when safeguard active', () {
    final rec = policy.profileSuggestion([
      _rec(id: 'pending'),
    ], activeSafeguard: _safeguard(id: 'sg-1'));
    expect(rec, isNull);
  });

  test('dashboardSuggestion returns at most one pending across pets', () {
    final rec = policy.dashboardSuggestion({
      'pet-1': [_rec(id: 'a', status: CareRecommendationStatus.dismissed)],
      'pet-2': [_rec(id: 'b')],
      'pet-3': [_rec(id: 'c')],
    });
    expect(rec?.id, 'b');
  });

  test('dashboardSuggestion suppressed when safeguard active', () {
    final rec = policy.dashboardSuggestion({
      'pet-2': [_rec(id: 'b')],
    }, activeSafeguard: _safeguard(id: 'sg-1'));
    expect(rec, isNull);
  });

  test('profileMilestoneMoment suppressed when safeguard active', () {
    final moment = policy.profileMilestoneMoment(
      _moment(petId: 'pet-1'),
      activeSafeguard: _safeguard(id: 'sg-1'),
    );
    expect(moment, isNull);
  });

  test('profileMilestoneMoment suppressed when suggestion active', () {
    final moment = policy.profileMilestoneMoment(
      _moment(petId: 'pet-1'),
      activeSuggestion: _rec(id: 'pending'),
    );
    expect(moment, isNull);
  });

  test('profileMilestoneMoment shown when no safeguard or suggestion', () {
    final input = _moment(petId: 'pet-1', bundleId: 'bundle-a');
    final moment = policy.profileMilestoneMoment(input);
    expect(moment?.bundleId, 'bundle-a');
  });

  test('dashboardMilestoneMoment returns at most one moment across pets', () {
    final moment = policy.dashboardMilestoneMoment({
      'pet-1': null,
      'pet-2': _moment(petId: 'pet-2', bundleId: 'bundle-b'),
      'pet-3': _moment(petId: 'pet-3', bundleId: 'bundle-c'),
    });
    expect(moment?.bundleId, 'bundle-b');
  });

  test('dashboardMilestoneMoment suppressed when suggestion active', () {
    final moment = policy.dashboardMilestoneMoment({
      'pet-1': _moment(petId: 'pet-1'),
    }, activeSuggestion: _rec(id: 'pending'));
    expect(moment, isNull);
  });

  test('dashboardSafeguard beats milestone and suggestion', () {
    final safeguard = policy.dashboardSafeguard({
      'pet-2': [_safeguard(id: 'sg-2', petId: 'pet-2')],
    });
    expect(safeguard?.id, 'sg-2');

    final suggestion = policy.dashboardSuggestion({
      'pet-1': [_rec(id: 'pending')],
    }, activeSafeguard: safeguard);
    final moment = policy.dashboardMilestoneMoment(
      {'pet-1': _moment(petId: 'pet-1')},
      activeSafeguard: safeguard,
      activeSuggestion: suggestion,
    );
    expect(suggestion, isNull);
    expect(moment, isNull);
  });
}
