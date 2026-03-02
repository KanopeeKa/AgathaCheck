import '../../domain/entities/health_issue.dart';

class HealthIssueModel extends HealthIssue {
  const HealthIssueModel({
    required super.id,
    required super.petId,
    required super.title,
    super.description,
    super.eventIds,
    super.startDate,
    super.endDate,
    super.createdAt,
    super.updatedAt,
  });

  factory HealthIssueModel.fromJson(Map<String, dynamic> json) {
    return HealthIssueModel(
      id: json['id'] as String? ?? '',
      petId: json['pet_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      eventIds: (json['event_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  factory HealthIssueModel.fromEntity(HealthIssue issue) {
    return HealthIssueModel(
      id: issue.id,
      petId: issue.petId,
      title: issue.title,
      description: issue.description,
      eventIds: issue.eventIds,
      startDate: issue.startDate,
      endDate: issue.endDate,
      createdAt: issue.createdAt,
      updatedAt: issue.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'title': title,
      'description': description,
      'event_ids': eventIds,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }

  HealthIssue toEntity() {
    return HealthIssue(
      id: id,
      petId: petId,
      title: title,
      description: description,
      eventIds: eventIds,
      startDate: startDate,
      endDate: endDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
