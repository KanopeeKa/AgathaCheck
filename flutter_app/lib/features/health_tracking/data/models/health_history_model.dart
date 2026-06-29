import '../../domain/entities/health_history_entry.dart';

/// Data model for [HealthHistoryEntry] with JSON serialization.
class HealthHistoryModel extends HealthHistoryEntry {
  const HealthHistoryModel({
    required super.id,
    required super.entryId,
    required super.markedAt,
    super.dueDate,
    super.completedOn,
    super.markedByUserId,
    super.markedByName,
    super.notes,
  });

  factory HealthHistoryModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw.contains('T') ? raw : '${raw}T00:00:00');
    }

    final markedRaw = json['marked_at'] ?? json['changed_at'] ?? json['taken_at'];
    return HealthHistoryModel(
      id: json['id'] as String? ?? '',
      entryId: (json['health_entry_id'] ?? json['entry_id']) as String? ?? '',
      markedAt: DateTime.tryParse(markedRaw as String? ?? '') ?? DateTime.now(),
      dueDate: parseDate(json['due_date'] as String?),
      completedOn: parseDate(json['completed_on'] as String?),
      markedByUserId: json['marked_by_user_id'] as String?,
      markedByName: json['marked_by_name'] as String?,
      notes: json['notes'] as String? ?? '',
    );
  }
}
