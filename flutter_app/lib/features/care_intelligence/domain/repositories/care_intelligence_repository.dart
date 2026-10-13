import '../entities/care_recommendation.dart';
import '../entities/care_safeguard.dart';
import '../entities/welfare_suggestion.dart';

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

  Future<List<WelfareSuggestion>> getWelfareSuggestions(String petId);

  Future<WelfareSuggestion> respondWelfareSuggestion({
    required String petId,
    required String suggestionId,
    required String action,
    String? primaryOutcome,
  });
}
