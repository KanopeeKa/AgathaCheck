/// Represents a health tracking entry in the domain layer.
///
/// A health entry tracks medications, preventives, or vaccines
/// for a pet with scheduling and dosage information.
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
    this.repeatEndDate,
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  /// Unique identifier.
  final String id;

  /// The pet this entry belongs to.
  final String petId;

  /// Name of the medication, preventive, or vaccine.
  final String name;

  /// Type of entry: medication, preventive, or vaccine.
  final HealthEntryType type;

  /// Dosage or amount information.
  final String dosage;

  /// How often this entry is due.
  final HealthFrequency frequency;

  /// Custom interval in days (used when [frequency] is [HealthFrequency.custom]).
  final int? frequencyDays;

  /// When repeating ends (null = never).
  final DateTime? repeatEndDate;

  /// When this health entry started.
  final DateTime startDate;

  /// When the next dose or action is due.
  final DateTime nextDueDate;

  /// Additional notes.
  final String notes;

  /// When this entry was created.
  final DateTime? createdAt;

  /// When this entry was last updated.
  final DateTime? updatedAt;

  /// Whether this entry is overdue.
  bool get isOverdue => nextDueDate.isBefore(DateTime.now());

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
    DateTime? repeatEndDate,
    bool clearRepeatEndDate = false,
    DateTime? startDate,
    DateTime? nextDueDate,
    String? notes,
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
      repeatEndDate: clearRepeatEndDate ? null : (repeatEndDate ?? this.repeatEndDate),
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      notes: notes ?? this.notes,
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

  /// A vaccine.
  vaccine,

  /// A medical procedure (surgery, dental, checkup, etc.).
  procedure;

  /// Human-readable label for this type.
  String get label {
    switch (this) {
      case HealthEntryType.medication:
        return 'Medication';
      case HealthEntryType.preventive:
        return 'Preventive';
      case HealthEntryType.vaccine:
        return 'Vaccine';
      case HealthEntryType.procedure:
        return 'Procedure';
    }
  }
}

/// How frequently a health entry is due.
enum HealthFrequency {
  /// Does not repeat — one-time event.
  once,

  /// Once per day.
  daily,

  /// Once per week.
  weekly,

  /// Once per month.
  monthly,

  /// Custom interval in days.
  custom;

  /// Human-readable label for this frequency.
  String get label {
    switch (this) {
      case HealthFrequency.once:
        return 'Does not repeat';
      case HealthFrequency.daily:
        return 'Daily';
      case HealthFrequency.weekly:
        return 'Weekly';
      case HealthFrequency.monthly:
        return 'Monthly';
      case HealthFrequency.custom:
        return 'Custom';
    }
  }
}
