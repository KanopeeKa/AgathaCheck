import '../../../pet_profile/pet_profile.dart';
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
      engineVersion: json['engine_version'] as String? ?? '1.0.0',
      knowledgeVersion: json['knowledge_version'] as String? ?? '1.0.0',
      suggestedName: json['suggested_name'] as String,
      suggestedFrequency: json['suggested_frequency'] as String,
      suggestedFrequencyInterval:
          (json['suggested_frequency_interval'] as num?)?.toInt() ?? 1,
      rationaleKey: json['rationale_key'] as String,
      healthEntryId: json['health_entry_id'] as String?,
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'] as String)
          : null,
    );
  }

  /// Maps inbox suggestion notifications (FR-SG-6 single API).
  factory CareRecommendationModel.fromSuggestionNotificationJson(
    Map<String, dynamic> json,
  ) {
    final payload = json['suggestion_payload'] is Map
        ? Map<String, dynamic>.from(json['suggestion_payload'] as Map)
        : <String, dynamic>{};
    final petId = json['pet_id']?.toString() ?? '';
    return CareRecommendationModel(
      id: json['id']?.toString() ?? '',
      petId: petId,
      careFamily:
          CareFamilyWire.fromWire(payload['care_family']?.toString()) ??
          CareFamily.other,
      suggestionKey: payload['suggestion_key']?.toString() ?? '',
      status: CareRecommendationStatus.pending,
      engineVersion: '1.0.0',
      knowledgeVersion: '1.0.0',
      suggestedName:
          payload['suggested_name']?.toString() ??
          json['title']?.toString() ??
          'Suggestion',
      suggestedFrequency:
          payload['suggested_frequency']?.toString() ?? 'monthly',
      suggestedFrequencyInterval:
          (payload['suggested_frequency_interval'] as num?)?.toInt() ?? 1,
      rationaleKey:
          payload['rationale_key']?.toString() ??
          json['message']?.toString() ??
          'careSuggestionGenericWhy',
      healthEntryId: payload['recommendation_id']?.toString(),
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
