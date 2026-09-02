import '../../domain/entities/health_occurrence.dart';
import '../../../../core/utils/calendar_date.dart';

class HealthOccurrenceModel extends HealthOccurrence {
  const HealthOccurrenceModel({
    required super.id,
    required super.entryId,
    required super.scheduledDate,
    super.scheduledTime,
    required super.status,
    super.completedOn,
    super.markedAt,
    super.markedByUserId,
    super.markedByName,
    super.notes,
    super.missed,
  });

  factory HealthOccurrenceModel.fromJson(Map<String, dynamic> json) {
    return HealthOccurrenceModel(
      id: json['id'] as String? ?? '',
      entryId:
          json['health_entry_id'] as String? ??
          json['entry_id'] as String? ??
          '',
      scheduledDate:
          parseCalendarDate(json['scheduled_date']) ??
          calendarDateOnly(DateTime.now()),
      scheduledTime: json['scheduled_time'] as String?,
      status: json['status'] as String? ?? 'pending',
      completedOn: parseCalendarDate(json['completed_on']),
      markedAt: json['marked_at'] != null
          ? DateTime.tryParse(json['marked_at'] as String)
          : null,
      markedByUserId: json['marked_by_user_id'] as String?,
      markedByName: json['marked_by_name'] as String?,
      notes: json['notes'] as String? ?? '',
      missed: json['missed'] as bool? ?? false,
    );
  }
}
