import '../entities/care_recommendation.dart';
import '../entities/care_safeguard.dart';

abstract class CareIntelligenceRepository {
  Future<List<CareRecommendation>> getRecommendations(String petId);

  Future<List<CareSafeguard>> getSafeguards(String petId);

  Future<CareSafeguard> dismissSafeguard({
    required String petId,
    required String safeguardId,
  });

  Future<CareRecommendation> respond({
    required String petId,
    required String recommendationId,
    required CareRecommendationResponseAction action,
    Map<String, dynamic>? adjust,
  });
}
