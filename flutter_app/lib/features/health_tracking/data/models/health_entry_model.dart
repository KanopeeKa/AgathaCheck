import '../../domain/entities/health_entry.dart';

/// Data model for [HealthEntry] with JSON serialization.
///
/// Extends the domain entity with serialization capabilities
/// for API communication.
class HealthEntryModel extends HealthEntry {
  /// Creates a [HealthEntryModel] instance.
  const HealthEntryModel({
    required super.id,
    required super.petId,
    required super.name,
    required super.type,
    required super.frequency,
    required super.startDate,
    required super.nextDueDate,
    super.dosage,
    super.frequencyDays,
    super.frequencyInterval,
    super.repeatEndDate,
    super.notes,
    super.healthIssueId,
    super.healthIssueName,
    super.remindDaysBefore,
    super.createdAt,
    super.updatedAt,
  });

  /// Creates a [HealthEntryModel] from a JSON map.
  factory HealthEntryModel.fromJson(Map<String, dynamic> json) {
    return HealthEntryModel(
      id: json['id'] as String? ?? '',
      petId: json['pet_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: _parseType(json['type'] as String? ?? 'medication'),
      dosage: json['dosage'] as String? ?? '',
      frequency: _parseFrequency(json['frequency'] as String? ?? 'once'),
      frequencyDays: json['frequency_days'] as int?,
      frequencyInterval: json['frequency_interval'] as int? ?? 1,
      repeatEndDate: json['repeat_end_date'] != null
          ? DateTime.tryParse(json['repeat_end_date'] as String)
          : null,
      startDate: DateTime.tryParse(json['start_date'] as String? ?? '') ??
          DateTime.now(),
      nextDueDate:
          DateTime.tryParse(json['next_due_date'] as String? ?? '') ??
              DateTime.now(),
      notes: json['notes'] as String? ?? '',
      healthIssueId: json['health_issue_id'] as String?,
      healthIssueName: json['health_issue_title'] as String?,
      remindDaysBefore: json['remind_days_before'] as int? ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Creates a [HealthEntryModel] from a domain [HealthEntry].
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
      notes: entry.notes,
      healthIssueId: entry.healthIssueId,
      healthIssueName: entry.healthIssueName,
      remindDaysBefore: entry.remindDaysBefore,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  /// Converts this model to a JSON map for API communication.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'name': name,
      'type': type == HealthEntryType.vetVisit ? 'vet_visit' : type.name,
      'dosage': dosage,
      'frequency': frequency.name,
      'frequency_days': frequencyDays,
      'frequency_interval': frequencyInterval,
      'repeat_end_date': repeatEndDate?.toIso8601String().split('T').first,
      'start_date': startDate.toIso8601String().split('T').first,
      'next_due_date': nextDueDate.toIso8601String(),
      'notes': notes,
      if (healthIssueId != null) 'health_issue_id': healthIssueId,
      'remind_days_before': remindDaysBefore,
    };
  }

  static HealthEntryType _parseType(String value) {
    switch (value) {
      case 'medication':
        return HealthEntryType.medication;
      case 'preventive':
        return HealthEntryType.preventive;
      case 'vet_visit':
      case 'vetVisit':
      case 'vaccine':
        return HealthEntryType.vetVisit;
      case 'procedure':
        return HealthEntryType.procedure;
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
