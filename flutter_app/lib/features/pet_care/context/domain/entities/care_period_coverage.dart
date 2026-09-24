enum CarePeriodCoverageState {
  nothingScheduled('nothing_scheduled'),
  allCompleted('all_completed'),
  noUnresolvedItems('no_unresolved_items'),
  hasItemsToReview('has_items_to_review'),
  indeterminate('indeterminate');

  const CarePeriodCoverageState(this.wireValue);

  final String wireValue;

  static CarePeriodCoverageState? fromWire(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final state in values) {
      if (state.wireValue == raw) return state;
    }
    return null;
  }
}

enum CarePeriodProjectionStatus {
  complete('complete'),
  partiallyIndeterminate('partially_indeterminate');

  const CarePeriodProjectionStatus(this.wireValue);

  final String wireValue;

  static CarePeriodProjectionStatus? fromWire(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final status in values) {
      if (status.wireValue == raw) return status;
    }
    return null;
  }
}

enum PlannedCareKind {
  recurringCalendar('recurring_calendar'),
  recurringChain('recurring_chain'),
  singleOnce('single_once'),
  indeterminatePending('indeterminate_pending');

  const PlannedCareKind(this.wireValue);

  final String wireValue;

  static PlannedCareKind? fromWire(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final kind in values) {
      if (kind.wireValue == raw) return kind;
    }
    return null;
  }

  bool get showsChainAnchorExplainer =>
      this == PlannedCareKind.recurringChain ||
      this == PlannedCareKind.indeterminatePending;
}

class CarePeriodProjectionItem {
  const CarePeriodProjectionItem({
    required this.healthEntryId,
    this.occurrenceId,
    required this.scheduledDate,
    this.scheduledTime,
    required this.status,
    required this.source,
    required this.name,
    required this.type,
    required this.careFamily,
  });

  final String healthEntryId;
  final String? occurrenceId;
  final String scheduledDate;
  final String? scheduledTime;
  final String status;
  final String source;
  final String name;
  final String type;
  final String careFamily;

  bool get isPending => status == 'pending';
}

class PlannedCareOpenOccurrence {
  const PlannedCareOpenOccurrence({
    this.occurrenceId,
    required this.scheduledDate,
    this.scheduledTime,
    required this.openStatus,
  });

  final String? occurrenceId;
  final String scheduledDate;
  final String? scheduledTime;

  /// `overdue` | `due_before_absence` | `in_window`
  final String openStatus;
}

class PlannedCareInWindow {
  const PlannedCareInWindow({
    required this.firstDate,
    required this.lastDate,
    required this.count,
    required this.dateBasis,
  });

  final String firstDate;
  final String lastDate;
  final int count;

  /// `scheduled` | `planned` | `estimated`
  final String dateBasis;
}

class PlannedCareItem {
  const PlannedCareItem({
    required this.kind,
    required this.healthEntryId,
    required this.name,
    this.type,
    this.careFamily,
    this.frequency,
    this.frequencyInterval = 1,
    this.timesOfDay = const [],
    this.nextDueDate,
    this.certainty,
    this.reason,
    this.occurrenceId,
    this.scheduledDate,
    this.status,
    this.firstScheduledDate,
    this.lastScheduledDate,
    this.occurrenceCount = 0,
    this.openOccurrence,
    this.inWindow,
    this.isPaused = false,
  });

  final PlannedCareKind kind;
  final String healthEntryId;
  final String name;
  final String? type;
  final String? careFamily;
  final String? frequency;
  final int frequencyInterval;
  final List<String> timesOfDay;
  final String? nextDueDate;
  final String? certainty;
  final String? reason;
  final String? occurrenceId;
  final String? scheduledDate;
  final String? status;
  final String? firstScheduledDate;
  final String? lastScheduledDate;
  final int occurrenceCount;
  final PlannedCareOpenOccurrence? openOccurrence;
  final PlannedCareInWindow? inWindow;
  final bool isPaused;

  bool get isConditional => certainty == 'conditional_on_future_completion';

  bool get usesAcpRowContract =>
      isPaused || openOccurrence != null || inWindow != null;
}

class CarePeriodCoverageSummary {
  const CarePeriodCoverageSummary({
    required this.policyVersion,
    required this.coverageState,
    required this.reasonCodes,
    required this.reassuranceAvailable,
  });

  final String policyVersion;
  final CarePeriodCoverageState coverageState;
  final List<String> reasonCodes;
  final bool reassuranceAvailable;
}

class CarePeriodCoverageResult {
  const CarePeriodCoverageResult({
    required this.startsOn,
    required this.endsOn,
    required this.projectionStatus,
    required this.items,
    required this.coverage,
    this.plannedCareItems = const [],
  });

  final String startsOn;
  final String endsOn;
  final CarePeriodProjectionStatus projectionStatus;
  final List<CarePeriodProjectionItem> items;
  final CarePeriodCoverageSummary coverage;
  final List<PlannedCareItem> plannedCareItems;

  bool get isPartiallyIndeterminate =>
      projectionStatus == CarePeriodProjectionStatus.partiallyIndeterminate;

  bool get showsEstimateFootnote => plannedCareItems.any(
    (item) => item.inWindow?.dateBasis == 'estimated',
  );

  bool get showsChainAnchorExplainer =>
      !showsEstimateFootnote &&
      plannedCareItems.any((item) => item.kind.showsChainAnchorExplainer);
}
