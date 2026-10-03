import 'care_occurrence.dart';

/// One occurrence for the occurrence screen (§18.7.1, D-CIE-029).
class OccurrenceDetail {
  const OccurrenceDetail({
    required this.occurrence,
    required this.item,
    this.lastAction,
    this.linkedWeight,
  });

  final CareOccurrence occurrence;
  final CareItemSummary item;

  /// The item's latest undoable action, for "Undo" on this occurrence.
  final CareLastAction? lastAction;

  /// The weight saved with a weigh-in.
  final LinkedWeight? linkedWeight;

  /// Undo is offered on this occurrence only when the item's last action is
  /// on it (§18.6.4).
  bool get canUndoHere => lastAction?.occurrenceId == occurrence.id;
}

/// An occurrence in any status.
class CareOccurrence {
  const CareOccurrence({
    required this.id,
    required this.date,
    required this.status,
    required this.origin,
    required this.isOpen,
    this.time,
    this.completedOn,
    this.notes = '',
  });

  final String id;
  final DateTime date;
  final String? time;

  /// Open: coming up / due / overdue / not recorded. Closed: done, skipped,
  /// or not recorded (closed by the three-day window).
  final CareOccurrenceStatus status;
  final CareOccurrenceOrigin origin;

  /// Still pending on the server.
  final bool isOpen;
  final DateTime? completedOn;
  final String notes;

  bool get isDone => status == CareOccurrenceStatus.done;
}

/// The care item fields the occurrence screen needs.
class CareItemSummary {
  const CareItemSummary({
    required this.id,
    required this.petId,
    required this.name,
    required this.isFixedSchedule,
    required this.status,
    required this.asOf,
    this.careFamily,
    this.lateCompletionChoice,
  });

  final String id;
  final String petId;
  final String name;
  final String? careFamily;
  final bool isFixedSchedule;
  final String status;
  final String? lateCompletionChoice;
  final CareAsOf asOf;
}

/// The ledger type of the item's latest undoable action.
class CareLastAction {
  const CareLastAction({required this.type, this.occurrenceId});

  /// `completed`, `completion_date_changed`, `skipped`, …
  final String type;
  final String? occurrenceId;

  bool get isCompletionDateChange => type == 'completion_date_changed';
}

class LinkedWeight {
  const LinkedWeight({required this.value, required this.unit});

  final double value;
  final String unit;
}
