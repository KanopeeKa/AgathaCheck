import '../../../pet_profile/domain/entities/care_family.dart';

enum CareRecommendationStatus {
  pending,
  accepted,
  adjusted,
  dismissed,
  notRelevant,
}

/// Server-authored care rhythm suggestion for a pet.
class CareRecommendation {
  const CareRecommendation({
    required this.id,
    required this.petId,
    required this.careFamily,
    required this.suggestionKey,
    required this.status,
    required this.engineVersion,
    required this.knowledgeVersion,
    required this.suggestedName,
    required this.suggestedFrequency,
    required this.suggestedFrequencyInterval,
    required this.suggestedHealthEntryType,
    required this.rationaleKey,
    this.healthEntryId,
    this.respondedAt,
  });

  final String id;
  final String petId;
  final CareFamily careFamily;
  final String suggestionKey;
  final CareRecommendationStatus status;
  final String engineVersion;
  final String knowledgeVersion;
  final String suggestedName;
  final String suggestedFrequency;
  final int suggestedFrequencyInterval;
  final String suggestedHealthEntryType;
  final String rationaleKey;
  final String? healthEntryId;
  final DateTime? respondedAt;

  bool get isPending => status == CareRecommendationStatus.pending;
}

enum CareRecommendationResponseAction {
  accept,
  adjust,
  dismiss,
  notRelevant,
}
