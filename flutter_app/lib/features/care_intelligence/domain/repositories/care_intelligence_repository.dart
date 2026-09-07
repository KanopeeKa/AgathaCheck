import '../entities/care_recommendation.dart';

abstract class CareIntelligenceRepository {
  Future<List<CareRecommendation>> getRecommendations(String petId);

  Future<CareRecommendation> respond({
    required String petId,
    required String recommendationId,
    required CareRecommendationResponseAction action,
    Map<String, dynamic>? adjust,
  });
}
