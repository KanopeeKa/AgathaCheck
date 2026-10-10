import '../../../care_taxonomy/care_taxonomy.dart';

enum HealthDocumentValidationError { unsupportedFormat, tooLarge }

enum HealthEntrySubmitValidation {
  nameRequired,
  dueOrCompletedRequired,
  completedOnRequired,
  noPetsSelected,
  careFamilyRequired,
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
    required this.entryIds,
    required this.careSetting,
    required this.carePlanning,
    this.linkedHealthIssueId,
    this.careSuggestionRoutineName,
  });

  final bool isEdit;
  final Set<String> petIds;
  final List<String> entryIds;
  final CareSetting careSetting;
  final CarePlanningMode carePlanning;
  final String? linkedHealthIssueId;
  final String? careSuggestionRoutineName;

  int get createdCount => petIds.length;
}

class HealthEntrySubmitError extends HealthEntrySubmitOutcome {
  HealthEntrySubmitError(this.error);
  final Object error;
}
