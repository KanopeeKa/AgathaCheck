import '../../../pet_profile/domain/entities/care_family.dart';
import '../../domain/entities/care_recommendation.dart';

class CareRecommendationModel {
  CareRecommendationModel({
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

  factory CareRecommendationModel.fromJson(Map<String, dynamic> json) {
    return CareRecommendationModel(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      careFamily:
          CareFamilyWire.fromWire(json['care_family'] as String?) ??
          CareFamily.other,
      suggestionKey: json['suggestion_key'] as String,
      status: _statusFromWire(json['status'] as String?),
      engineVersion: json['engine_version'] as String,
      knowledgeVersion: json['knowledge_version'] as String,
      suggestedName: json['suggested_name'] as String,
      suggestedFrequency: json['suggested_frequency'] as String,
      suggestedFrequencyInterval:
          (json['suggested_frequency_interval'] as num?)?.toInt() ?? 1,
      suggestedHealthEntryType:
          json['suggested_health_entry_type'] as String? ?? 'other',
      rationaleKey: json['rationale_key'] as String,
      healthEntryId: json['health_entry_id'] as String?,
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'] as String)
          : null,
    );
  }

  CareRecommendation toEntity() => CareRecommendation(
    id: id,
    petId: petId,
    careFamily: careFamily,
    suggestionKey: suggestionKey,
    status: status,
    engineVersion: engineVersion,
    knowledgeVersion: knowledgeVersion,
    suggestedName: suggestedName,
    suggestedFrequency: suggestedFrequency,
    suggestedFrequencyInterval: suggestedFrequencyInterval,
    suggestedHealthEntryType: suggestedHealthEntryType,
    rationaleKey: rationaleKey,
    healthEntryId: healthEntryId,
    respondedAt: respondedAt,
  );

  static CareRecommendationStatus _statusFromWire(String? raw) {
    return switch (raw) {
      'accepted' => CareRecommendationStatus.accepted,
      'adjusted' => CareRecommendationStatus.adjusted,
      'dismissed' => CareRecommendationStatus.dismissed,
      'not_relevant' => CareRecommendationStatus.notRelevant,
      _ => CareRecommendationStatus.pending,
    };
  }
}

String careRecommendationStatusWire(CareRecommendationResponseAction action) {
  return switch (action) {
    CareRecommendationResponseAction.accept => 'accept',
    CareRecommendationResponseAction.adjust => 'adjust',
    CareRecommendationResponseAction.dismiss => 'dismiss',
    CareRecommendationResponseAction.notRelevant => 'not_relevant',
  };
}
