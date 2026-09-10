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

class CarePeriodUncertainty {
  const CarePeriodUncertainty({
    required this.healthEntryId,
    required this.reason,
  });

  final String healthEntryId;
  final String reason;
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
    required this.uncertainties,
    required this.items,
    required this.coverage,
  });

  final String startsOn;
  final String endsOn;
  final CarePeriodProjectionStatus projectionStatus;
  final List<CarePeriodUncertainty> uncertainties;
  final List<CarePeriodProjectionItem> items;
  final CarePeriodCoverageSummary coverage;

  bool get isPartiallyIndeterminate =>
      projectionStatus == CarePeriodProjectionStatus.partiallyIndeterminate;
}
