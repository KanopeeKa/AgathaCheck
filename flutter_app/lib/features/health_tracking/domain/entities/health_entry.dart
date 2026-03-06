/// Represents a health tracking entry in the domain layer.
///
/// A health entry tracks medications, preventives, vet visits,
/// or other health events for a pet with scheduling and dosage information.
class HealthEntry {
  /// Creates a new [HealthEntry] instance.
  const HealthEntry({
    required this.id,
    required this.petId,
    required this.name,
    required this.type,
    required this.frequency,
    required this.startDate,
    required this.nextDueDate,
    this.dosage = '',
    this.frequencyDays,
    this.frequencyInterval = 1,
    this.repeatEndDate,
    this.notes = '',
    this.healthIssueId,
    this.healthIssueName,
    this.remindDaysBefore = 1,
    this.createdAt,
    this.updatedAt,
  });

  /// Unique identifier.
  final String id;

  /// The pet this entry belongs to.
  final String petId;

  /// Name of the medication, preventive, vet visit, or other event.
  final String name;

  /// Type of entry: medication, preventive, vet visit, or other.
  final HealthEntryType type;

  /// Dosage or amount information.
  final String dosage;

  /// How often this entry is due.
  final HealthFrequency frequency;

  /// Custom interval in days (used when [frequency] is [HealthFrequency.custom]).
  final int? frequencyDays;

  /// Interval multiplier for the frequency (e.g., every 2 weeks = interval 2 + weekly).
  final int frequencyInterval;

  /// When repeating ends (null = never).
  final DateTime? repeatEndDate;

  /// When this health entry started.
  final DateTime startDate;

  /// When the next dose or action is due.
  final DateTime nextDueDate;

  /// Additional notes.
  final String notes;

  /// The health issue this entry is linked to, if any.
  final String? healthIssueId;

  /// The title of the linked health issue, if any.
  final String? healthIssueName;

  /// How many days before the due date to send a reminder notification.
  final int remindDaysBefore;

  /// When this entry was created.
  final DateTime? createdAt;

  /// When this entry was last updated.
  final DateTime? updatedAt;

  /// Whether a one-time entry has been completed (marked taken).
  bool get isCompleted =>
      frequency == HealthFrequency.once && nextDueDate.year >= 9999;

  /// Whether this entry is overdue (before today, not including today).
  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return dueDay.isBefore(today);
  }

  /// Whether this entry is due today.
  bool get isDueToday {
    final now = DateTime.now();
    return nextDueDate.year == now.year &&
        nextDueDate.month == now.month &&
        nextDueDate.day == now.day;
  }

  /// Whether this entry is due within the next 24 hours.
  bool get isDueSoon =>
      !isOverdue &&
      nextDueDate.isBefore(DateTime.now().add(const Duration(hours: 24)));

  /// Creates a copy of this entry with the given fields replaced.
  HealthEntry copyWith({
    String? id,
    String? petId,
    String? name,
    HealthEntryType? type,
    String? dosage,
    HealthFrequency? frequency,
    int? frequencyDays,
    int? frequencyInterval,
    DateTime? repeatEndDate,
    bool clearRepeatEndDate = false,
    DateTime? startDate,
    DateTime? nextDueDate,
    String? notes,
    String? healthIssueId,
    String? healthIssueName,
    bool clearHealthIssueId = false,
    int? remindDaysBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthEntry(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      name: name ?? this.name,
      type: type ?? this.type,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      frequencyDays: frequencyDays ?? this.frequencyDays,
      frequencyInterval: frequencyInterval ?? this.frequencyInterval,
      repeatEndDate: clearRepeatEndDate ? null : (repeatEndDate ?? this.repeatEndDate),
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      notes: notes ?? this.notes,
      healthIssueId: clearHealthIssueId ? null : (healthIssueId ?? this.healthIssueId),
      healthIssueName: clearHealthIssueId ? null : (healthIssueName ?? this.healthIssueName),
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// The type of health entry.
enum HealthEntryType {
  /// A regular medication.
  medication,

  /// A preventive treatment (flea, tick, heartworm, etc.).
  preventive,

  /// A vet visit (checkup, dental, surgery, etc.).
  vetVisit,

  /// Any other health event.
  procedure,

  /// A family event from an organization pet.
  familyEvent;

  /// Human-readable label for this type.
  String get label {
    switch (this) {
      case HealthEntryType.medication:
        return 'Medication';
      case HealthEntryType.preventive:
        return 'Preventive';
      case HealthEntryType.vetVisit:
        return 'Vet Visit';
      case HealthEntryType.procedure:
        return 'Other';
      case HealthEntryType.familyEvent:
        return 'Family Event';
    }
  }
}

/// How frequently a health entry is due.
enum HealthFrequency {
  /// Does not repeat — one-time event.
  once,

  /// Repeats per day(s).
  daily,

  /// Repeats per week(s).
  weekly,

  /// Repeats per month(s).
  monthly,

  /// Repeats per year(s).
  yearly,

  /// Custom interval in days (legacy).
  custom;

  /// Human-readable label for this frequency.
  String get label {
    switch (this) {
      case HealthFrequency.once:
        return 'Does not repeat';
      case HealthFrequency.daily:
        return 'Day';
      case HealthFrequency.weekly:
        return 'Week';
      case HealthFrequency.monthly:
        return 'Month';
      case HealthFrequency.yearly:
        return 'Year';
      case HealthFrequency.custom:
        return 'Custom';
    }
  }
}
