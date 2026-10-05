import '../../domain/entities/health_history_entry.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../../../core/weight/weight_unit.dart';

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
    super.status,
    super.linkedWeight,
  });

  factory HealthHistoryModel.fromJson(Map<String, dynamic> json) {
    final markedRaw =
        json['marked_at'] ?? json['changed_at'] ?? json['taken_at'];
    return HealthHistoryModel(
      id: json['id'] as String? ?? '',
      entryId: (json['health_entry_id'] ?? json['entry_id']) as String? ?? '',
      markedAt: DateTime.tryParse(markedRaw as String? ?? '') ?? DateTime.now(),
      dueDate: parseCalendarDate(json['due_date']),
      completedOn: parseCalendarDate(json['completed_on']),
      markedByUserId: json['marked_by_user_id'] as String?,
      markedByName: json['marked_by_name'] as String?,
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? 'completed',
      linkedWeight: _parseLinkedWeight(json['linked_weight']),
    );
  }

  static HealthHistoryLinkedWeight? _parseLinkedWeight(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final value = (raw['value'] as num?)?.toDouble();
    if (value == null) return null;
    final unit = raw['unit'] as String? ?? 'kg';
    final valueKg = unit == 'lb' ? toKg(value, WeightUnit.lb) : value;
    return HealthHistoryLinkedWeight(
      valueKg: valueKg,
      date: parseCalendarDate(raw['date']),
    );
  }
}
