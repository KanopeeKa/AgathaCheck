import '../../domain/entities/health_issue.dart';

class HealthIssueModel extends HealthIssue {
  const HealthIssueModel({
    required super.id,
    required super.petId,
    required super.title,
    super.description,
    super.eventIds,
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
    };
  }

  HealthIssue toEntity() {
    return HealthIssue(
      id: id,
      petId: petId,
      title: title,
      description: description,
      eventIds: eventIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
