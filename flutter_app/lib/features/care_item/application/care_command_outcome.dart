import '../domain/care_item_schedule.dart';

/// Why a care command or read did not succeed (§18.10). Mapped from HTTP and
/// network errors by `CareCompletionService`; never shown raw.
sealed class CareCommandFailure {
  const CareCommandFailure();

  /// Fixed analytics value (`care_done_failed`).
  String get analyticsValue;
}

/// No answer from the server (offline, timeout, session expired).
class CareNetworkFailure extends CareCommandFailure {
  const CareNetworkFailure();

  @override
  String get analyticsValue => 'network';
}

/// 400: the server refused the input; nothing was saved. [code] is the
/// server's stable code (or a local one, e.g. `weight_required`).
class CareValidationFailure extends CareCommandFailure {
  const CareValidationFailure(this.code);

  final String code;

  @override
  String get analyticsValue => 'validation';
}

/// 409 `occurrence_not_open`, or 404 for an occurrence that no longer exists:
/// someone else already updated it (DN-9). Reload silently, "Already updated".
class CareNotOpenFailure extends CareCommandFailure {
  const CareNotOpenFailure({this.gone = false});

  /// The occurrence no longer exists (404), e.g. removed by an undo (OS-5).
  final bool gone;

  @override
  String get analyticsValue => 'not_open';
}

/// Another 409 (e.g. `undo_stale`, `occurrence_not_completed`).
class CareConflictFailure extends CareCommandFailure {
  const CareConflictFailure(this.code);

  final String? code;

  @override
  String get analyticsValue => 'conflict';
}

class CareUnknownFailure extends CareCommandFailure {
  const CareUnknownFailure([this.statusCode]);

  final int? statusCode;

  @override
  String get analyticsValue => 'unknown';
}

/// What a successful command returned.
class CareCommandResult {
  const CareCommandResult({
    required this.entryId,
    this.occurrenceId,
    this.schedule,
    this.undoToken,
    this.nextChoiceApplied,
    this.nextDueDate,
    this.movedNextId,
    this.nextUnchanged = false,
  });

  final String entryId;
  final String? occurrenceId;

  /// The care item after the command, when the route returns it (the weight
  /// route does not; reload the item then).
  final CareItemSchedule? schedule;

  final String? undoToken;

  /// Completions done late with a waiting date: the choice the server applied
  /// (`keep`, `skip_next`, `shift_following`), else null (D-CSM-026).
  final String? nextChoiceApplied;

  final DateTime? nextDueDate;

  /// Completion date change (D-CSM-034): the computed next date it re-dated.
  final String? movedNextId;

  /// Completion date change: the next date was moved by a person and stays.
  final bool nextUnchanged;
}

/// A command answer: success with its result, or a mapped failure.
sealed class CareOutcome<T> {
  const CareOutcome();
}

class CareSucceeded<T> extends CareOutcome<T> {
  const CareSucceeded(this.value);

  final T value;
}

class CareFailed<T> extends CareOutcome<T> {
  const CareFailed(this.failure);

  final CareCommandFailure failure;
}
