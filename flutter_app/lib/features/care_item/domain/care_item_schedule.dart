import 'care_occurrence.dart';

/// The schedule side of a care item, as list and detail reads return it
/// (`open_occurrences`, `as_of`, `estimated_next`, D-CIE-028).
class CareItemSchedule {
  CareItemSchedule({
    required this.entryId,
    required this.petId,
    required this.name,
    required this.isFixedSchedule,
    required this.status,
    required List<OpenOccurrence> openOccurrences,
    required this.asOf,
    this.careFamily,
    this.estimatedNext,
    this.lateCompletionChoice,
    this.pausedUntil,
    this.resumeDefaultDate,
    this.repeatsDailyOrMore = false,
    this.intervalDays,
    this.lastDone,
  }) : openOccurrences = List.unmodifiable(
         [...openOccurrences]..sort((a, b) => a.compareTo(b)),
       );

  final String entryId;
  final String petId;
  final String name;

  /// Taxonomy family (`weight_monitoring`, `medication`, …).
  final String? careFamily;

  /// Fixed schedule (`from_due_date`); otherwise After it's done.
  final bool isFixedSchedule;

  /// `active`, `paused` or `completed`.
  final String status;

  /// Open occurrences, earliest first.
  final List<OpenOccurrence> openOccurrences;

  final CareAsOf asOf;
  final EstimatedNext? estimatedNext;

  /// Remembered next-date choice (`keep`, `skip_next`, `shift_following`).
  final String? lateCompletionChoice;

  final DateTime? pausedUntil;
  final DateTime? resumeDefaultDate;

  /// Daily or more often: shown only in Today (D-CIE-025).
  final bool repeatsDailyOrMore;

  /// Approximate days between dates (early-completion check, D-CSM-030);
  /// null for one-off care.
  final int? intervalDays;

  /// Latest completion, for "done today" rows.
  final LastDone? lastDone;

  bool get isActive => status == 'active';

  /// Done on the item's today (pet home calendar).
  bool get doneToday => lastDone?.completedOn == asOf.date;
  bool get isPaused => status == 'paused';
}

/// The latest completion of a care item.
class LastDone {
  const LastDone({required this.occurrenceId, this.completedOn, this.time});

  final String occurrenceId;
  final DateTime? completedOn;

  /// When it was marked, `HH:mm` in the pet's home zone.
  final String? time;
}
