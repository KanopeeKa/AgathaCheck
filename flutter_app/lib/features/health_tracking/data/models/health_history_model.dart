import '../../domain/entities/health_history_entry.dart';
import '../../../../core/utils/calendar_date.dart';

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
    final markedRaw = json['marked_at'] ?? json['changed_at'] ?? json['taken_at'];
    return HealthHistoryModel(
      id: json['id'] as String? ?? '',
      entryId: (json['health_entry_id'] ?? json['entry_id']) as String? ?? '',
      markedAt: DateTime.tryParse(markedRaw as String? ?? '') ?? DateTime.now(),
      dueDate: parseCalendarDate(json['due_date']),
      completedOn: parseCalendarDate(json['completed_on']),
      markedByUserId: json['marked_by_user_id'] as String?,
      markedByName: json['marked_by_name'] as String?,
      notes: json['notes'] as String? ?? '',
    );
  }
}
