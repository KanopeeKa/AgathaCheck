class HealthEntryPhoto {
  final String id;
  final String eventId;
  final String photoPath;
  final String caption;
  final String createdAt;
  final String? occurrenceId;

  HealthEntryPhoto({
    required this.id,
    required this.eventId,
    required this.photoPath,
    this.caption = '',
    this.createdAt = '',
    this.occurrenceId,
  });

  factory HealthEntryPhoto.fromJson(Map<String, dynamic> json) {
    return HealthEntryPhoto(
      id: (json['id'] ?? '').toString(),
      eventId: (json['event_id'] ?? json['health_entry_id'] ?? '').toString(),
      photoPath: (json['photo_path'] ?? json['url'] ?? '').toString(),
      caption: json['caption'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      occurrenceId: json['health_occurrence_id'] as String?,
    );
  }
}

/// Legacy name used across health entry UI and data mapping.
typedef EventPhoto = HealthEntryPhoto;
