import '../../domain/entities/health_entry.dart';
import '../../domain/entities/recurrence_anchor.dart';

enum HealthDocumentValidationError {
  unsupportedFormat,
  tooLarge,
}

enum HealthEntrySubmitValidation {
  dueOrCompletedRequired,
  noPetsSelected,
}

/// When creating a one-off entry with a due date on or before today.
class HealthEntryMarkCompletedPrompt {
  const HealthEntryMarkCompletedPrompt({
    required this.dueOnly,
    required this.todayOnly,
    required this.isPast,
  });

  final DateTime dueOnly;
  final DateTime todayOnly;
  final bool isPast;
}

sealed class HealthEntrySubmitOutcome {}

class HealthEntrySubmitValidationFailed extends HealthEntrySubmitOutcome {
  HealthEntrySubmitValidationFailed(this.reason);
  final HealthEntrySubmitValidation reason;
}

class HealthEntrySubmitNeedsMarkCompleted extends HealthEntrySubmitOutcome {
  HealthEntrySubmitNeedsMarkCompleted(this.prompt);
  final HealthEntryMarkCompletedPrompt prompt;
}

class HealthEntrySubmitSuccess extends HealthEntrySubmitOutcome {
  HealthEntrySubmitSuccess({
    required this.isEdit,
    required this.petIds,
  });

  final bool isEdit;
  final Set<String> petIds;

  int get createdCount => petIds.length;
}

class HealthEntrySubmitError extends HealthEntrySubmitOutcome {
  HealthEntrySubmitError(this.error);
  final Object error;
}

/// Text fields passed from the screen's [TextEditingController]s on submit.
class HealthEntryFormTextValues {
  const HealthEntryFormTextValues({
    required this.name,
    required this.dosage,
    required this.notes,
  });

  final String name;
  final String dosage;
  final String notes;
}

/// Populated entry fields after a successful load for edit mode.
class HealthEntryLoadedFormData {
  const HealthEntryLoadedFormData({
    required this.name,
    required this.dosage,
    required this.notes,
    required this.type,
    required this.frequency,
    required this.frequencyInterval,
    required this.startDate,
    required this.dueDate,
    required this.completedOn,
    required this.recurrenceAnchor,
    required this.repeatEndDate,
    required this.remindDaysBefore,
    required this.healthIssueId,
    required this.petId,
  });

  final String name;
  final String dosage;
  final String notes;
  final HealthEntryType type;
  final HealthFrequency frequency;
  final int frequencyInterval;
  final DateTime startDate;
  final DateTime? dueDate;
  final DateTime? completedOn;
  final RecurrenceAnchor recurrenceAnchor;
  final DateTime? repeatEndDate;
  final int remindDaysBefore;
  final String? healthIssueId;
  final String petId;
}
