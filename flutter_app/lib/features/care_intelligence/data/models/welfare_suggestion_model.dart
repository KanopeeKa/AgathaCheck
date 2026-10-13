import '../../domain/entities/welfare_suggestion.dart';

class WelfareSuggestionModel {
  const WelfareSuggestionModel({
    required this.id,
    required this.petId,
    required this.subjectKey,
    required this.dedupeKey,
    required this.rationaleKey,
    required this.engineVersion,
    required this.severity,
    this.createdAt,
  });

  final String id;
  final String petId;
  final String subjectKey;
  final String dedupeKey;
  final String rationaleKey;
  final String engineVersion;
  final int severity;
  final DateTime? createdAt;

  factory WelfareSuggestionModel.fromJson(Map<String, dynamic> json) {
    return WelfareSuggestionModel(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      subjectKey: json['subject_key'] as String,
      dedupeKey: json['dedupe_key'] as String,
      rationaleKey: json['rationale_key'] as String,
      engineVersion: json['engine_version'] as String,
      severity: (json['severity'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  WelfareSuggestion toEntity() => WelfareSuggestion(
    id: id,
    petId: petId,
    subjectKey: subjectKey,
    dedupeKey: dedupeKey,
    rationaleKey: rationaleKey,
    engineVersion: engineVersion,
    severity: severity,
    createdAt: createdAt,
  );
}
