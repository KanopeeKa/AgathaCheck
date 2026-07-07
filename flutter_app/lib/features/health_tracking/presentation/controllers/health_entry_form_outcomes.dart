enum HealthDocumentValidationError { unsupportedFormat, tooLarge }

enum HealthEntrySubmitValidation {
  nameRequired,
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
  HealthEntrySubmitSuccess({required this.isEdit, required this.petIds});

  final bool isEdit;
  final Set<String> petIds;

  int get createdCount => petIds.length;
}

class HealthEntrySubmitError extends HealthEntrySubmitOutcome {
  HealthEntrySubmitError(this.error);
  final Object error;
}
