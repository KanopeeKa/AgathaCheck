class HealthIssue {
  const HealthIssue({
    required this.id,
    required this.petId,
    required this.title,
    this.description = '',
    this.eventIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String petId;
  final String title;
  final String description;
  final List<String> eventIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HealthIssue copyWith({
    String? id,
    String? petId,
    String? title,
    String? description,
    List<String>? eventIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      HealthIssue(
        id: id ?? this.id,
        petId: petId ?? this.petId,
        title: title ?? this.title,
        description: description ?? this.description,
        eventIds: eventIds ?? this.eventIds,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HealthIssue && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
