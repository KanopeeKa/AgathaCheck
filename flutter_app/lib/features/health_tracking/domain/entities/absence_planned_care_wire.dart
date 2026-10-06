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
    this.scheduleFlexibility,
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
  final String? scheduleFlexibility;

  /// Real occurrence id for away-plan navigation (matches pet_care PlannedCareItem).
  String? get resolvedOccurrenceId {
    final fromOpen = openOccurrence?.occurrenceId;
    if (fromOpen != null && fromOpen.isNotEmpty) return fromOpen;
    if (occurrenceId != null && occurrenceId!.isNotEmpty) return occurrenceId;
    return null;
  }
}
