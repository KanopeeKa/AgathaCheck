import '../../domain/entities/health_entry.dart';
import '../../domain/entities/recurrence_anchor.dart';
import '../../../../core/utils/calendar_date.dart';

/// Data model for [HealthEntry] with JSON serialization.
class HealthEntryModel extends HealthEntry {
  const HealthEntryModel({
    required super.id,
    required super.petId,
    required super.name,
    required super.type,
    required super.frequency,
    required super.startDate,
    super.nextDueDate,
    super.completedOn,
    super.recurrenceAnchor,
    super.dosage,
    super.frequencyDays,
    super.frequencyInterval,
    super.repeatEndDate,
    super.notes,
    super.healthIssueId,
    super.healthIssueName,
    super.petName,
    super.remindDaysBefore,
    super.createdAt,
    super.updatedAt,
  });

  factory HealthEntryModel.fromJson(Map<String, dynamic> json) {
    final nextDue = parseCalendarDate(json['next_due_date']);
    final completedOn = parseCalendarDate(json['completed_on']);

    return HealthEntryModel(
      id: json['id'] as String? ?? '',
      petId: json['pet_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: _parseType(json['type'] as String? ?? 'medication'),
      dosage: json['dosage'] as String? ?? '',
      frequency: _parseFrequency(json['frequency'] as String? ?? 'once'),
      frequencyDays: json['frequency_days'] as int?,
      frequencyInterval: json['frequency_interval'] as int? ?? 1,
      repeatEndDate: parseCalendarDate(json['repeat_end_date']),
      startDate:
          parseCalendarDate(json['start_date']) ??
          calendarDateOnly(DateTime.now()),
      nextDueDate: nextDue,
      completedOn: completedOn,
      recurrenceAnchor: RecurrenceAnchorApi.fromApi(
        json['recurrence_anchor'] as String?,
      ),
      notes: json['notes'] as String? ?? '',
      healthIssueId: json['health_issue_id'] as String?,
      healthIssueName: json['health_issue_title'] as String?,
      petName: json['pet_name'] as String?,
      remindDaysBefore: json['remind_days_before'] as int? ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  factory HealthEntryModel.fromEntity(HealthEntry entry) {
    return HealthEntryModel(
      id: entry.id,
      petId: entry.petId,
      name: entry.name,
      type: entry.type,
      dosage: entry.dosage,
      frequency: entry.frequency,
      frequencyDays: entry.frequencyDays,
      frequencyInterval: entry.frequencyInterval,
      repeatEndDate: entry.repeatEndDate,
      startDate: entry.startDate,
      nextDueDate: entry.nextDueDate,
      completedOn: entry.completedOn,
      recurrenceAnchor: entry.recurrenceAnchor,
      notes: entry.notes,
      healthIssueId: entry.healthIssueId,
      healthIssueName: entry.healthIssueName,
      petName: entry.petName,
      remindDaysBefore: entry.remindDaysBefore,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'name': name,
      'type': typeToApi(type),
      'dosage': dosage,
      'frequency': frequencyToApi(frequency),
      'frequency_days': frequencyDays,
      'frequency_interval': frequencyInterval,
      'repeat_end_date': toCalendarDateString(repeatEndDate),
      'start_date': toCalendarDateString(startDate),
      if (nextDueDate != null)
        'next_due_date': toCalendarDateString(nextDueDate),
      if (completedOn != null)
        'completed_on': toCalendarDateString(completedOn),
      'recurrence_anchor': recurrenceAnchor.apiValue,
      'notes': notes,
      if (healthIssueId != null) 'health_issue_id': healthIssueId,
      'remind_days_before': remindDaysBefore,
    };
  }

  static String typeToApi(HealthEntryType type) {
    switch (type) {
      case HealthEntryType.medication:
        return 'medication';
      case HealthEntryType.preventive:
        return 'preventive';
      case HealthEntryType.vetVisit:
        return 'vet_visit';
      case HealthEntryType.procedure:
        return 'procedure';
      case HealthEntryType.familyEvent:
        return 'family_event';
    }
  }

  static String frequencyToApi(HealthFrequency frequency) {
    switch (frequency) {
      case HealthFrequency.once:
        return 'once';
      case HealthFrequency.daily:
        return 'daily';
      case HealthFrequency.weekly:
        return 'weekly';
      case HealthFrequency.monthly:
        return 'monthly';
      case HealthFrequency.yearly:
        return 'yearly';
      case HealthFrequency.custom:
        return 'custom';
    }
  }

  static HealthEntryType _parseType(String value) {
    switch (value) {
      case 'medication':
        return HealthEntryType.medication;
      case 'preventive':
        return HealthEntryType.preventive;
      case 'vaccine':
        return HealthEntryType.preventive;
      case 'vet_visit':
      case 'vetVisit':
        return HealthEntryType.vetVisit;
      case 'procedure':
        return HealthEntryType.procedure;
      case 'family_event':
      case 'familyEvent':
        return HealthEntryType.familyEvent;
      default:
        return HealthEntryType.medication;
    }
  }

  static HealthFrequency _parseFrequency(String value) {
    switch (value) {
      case 'once':
        return HealthFrequency.once;
      case 'daily':
        return HealthFrequency.daily;
      case 'weekly':
        return HealthFrequency.weekly;
      case 'monthly':
        return HealthFrequency.monthly;
      case 'yearly':
        return HealthFrequency.yearly;
      case 'custom':
        return HealthFrequency.custom;
      default:
        return HealthFrequency.once;
    }
  }
}
