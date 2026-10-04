import 'dart:async';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../../../core/network/auth_http_client.dart';
import '../../../core/utils/calendar_date.dart';
import '../data/care_item_remote_datasource.dart';
import '../data/care_item_wire.dart';
import '../domain/care_item_schedule.dart';
import '../domain/completion_requirements.dart';
import '../domain/occurrence_detail.dart';
import 'care_command_outcome.dart';

/// Where a command started, for audit metadata (§18.10). Fixed values only.
enum CareCommandSource { agenda, careItem, occurrence, dashboard, notification }

/// How it was sent.
enum CareCommandPath { oneTap, dateSheet, earlyDialog, occurrenceScreen, stack }

String _snake(String camel) =>
    camel.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

/// One completion (§18.6.1). The flow decides whether to send it; the service
/// only sends it.
class CareCompletionRequest {
  const CareCompletionRequest({
    required this.petId,
    required this.entryId,
    required this.occurrenceId,
    required this.careFamily,
    required this.source,
    required this.path,
    this.completedOn,
    this.inputs = const CompletionInputs(),
    this.notes = '',
  });

  final String petId;
  final String entryId;
  final String occurrenceId;
  final String? careFamily;

  /// Defaults to the server's today; send the pet-home day for a weigh-in.
  final DateTime? completedOn;
  final CompletionInputs inputs;
  final String notes;
  final CareCommandSource source;
  final CareCommandPath path;
}

/// Sends completions and occurrence edits, and maps every answer to a
/// [CareOutcome]. The only client of the completion routes (§18.8).
///
/// Never sends `next_choice` or `earlier_choice`: the server applies the
/// remembered choice or keeps the waiting date (D-CSM-026, DN-6).
class CareCompletionService {
  CareCompletionService(this._remote);

  final CareItemRemoteDataSource _remote;

  Future<CareOutcome<CareCommandResult>> complete(
    CareCompletionRequest request,
  ) {
    final missing = missingRequirements(request.careFamily, request.inputs);
    if (missing.isNotEmpty) {
      return Future.value(
        CareFailed(CareValidationFailure('${missing.first.name}_required')),
      );
    }
    final tags = {
      'source': _snake(request.source.name),
      'path': _snake(request.path.name),
    };
    final completedOn = toCalendarDateString(request.completedOn);
    return _run('complete', () async {
      switch (completionEndpointFor(request.careFamily)) {
        case CompletionEndpoint.complete:
          final body = await _remote
              .postComplete(request.entryId, request.occurrenceId, {
                'completed_on': ?completedOn,
                if (request.notes.isNotEmpty) 'notes': request.notes,
                ...tags,
              });
          return _commandResult(request.entryId, body);
        case CompletionEndpoint.completeWeight:
          final body = await _remote.postCompleteWeight(
            request.petId,
            request.entryId,
            request.occurrenceId,
            {
              'weight': request.inputs.weightValue,
              'unit': request.inputs.weightUnit,
              'date': ?completedOn,
              'completed_on': ?completedOn,
              if (request.notes.isNotEmpty) 'notes': request.notes,
              ...tags,
            },
          );
          return _commandResult(request.entryId, body);
      }
    });
  }

  /// Change when a completed occurrence was done (D-CSM-034).
  Future<CareOutcome<CareCommandResult>> changeCompletionDate({
    required String entryId,
    required String occurrenceId,
    required DateTime completedOn,
  }) {
    return _run('completion_date', () async {
      final body = await _remote.patchOccurrence(entryId, occurrenceId, {
        'completed_on': toCalendarDateString(completedOn),
      });
      return _commandResult(entryId, body);
    });
  }

  /// Skip one open occurrence.
  Future<CareOutcome<CareCommandResult>> skip({
    required String entryId,
    required String occurrenceId,
  }) {
    return _run('skip', () async {
      final body = await _remote.postOccurrenceAction(
        entryId,
        occurrenceId,
        'skip',
        const {},
      );
      return _commandResult(entryId, body);
    });
  }

  /// Record a closed Not recorded date as done (D-CSM-023).
  Future<CareOutcome<CareCommandResult>> recordAsDone({
    required String entryId,
    required String occurrenceId,
    required DateTime completedOn,
  }) {
    return _run('record', () async {
      final body = await _remote.postOccurrenceAction(
        entryId,
        occurrenceId,
        'record',
        {'completed_on': toCalendarDateString(completedOn)},
      );
      return _commandResult(entryId, body);
    });
  }

  /// Move one open occurrence to [date] (this date only).
  Future<CareOutcome<CareCommandResult>> changeDate({
    required String entryId,
    required String occurrenceId,
    required DateTime date,
  }) {
    return _run('change_date', () async {
      final body = await _remote.postOccurrenceAction(
        entryId,
        occurrenceId,
        'reschedule',
        {'scheduled_date': toCalendarDateString(date), 'scope': 'this'},
      );
      return _commandResult(entryId, body);
    });
  }

  /// Add a planned occurrence (D-CSM-025).
  Future<CareOutcome<CareCommandResult>> planAnotherDate({
    required String entryId,
    required DateTime date,
    String? time,
  }) {
    return _run('plan_date', () async {
      final body = await _remote.postPlanAnotherDate(entryId, {
        'scheduled_date': toCalendarDateString(date),
        if (time != null && time.isNotEmpty) 'scheduled_time': time,
      });
      return _commandResult(entryId, body);
    });
  }

  /// Stack bulk action (§18.6.5): [given] closes as done on each slot's own
  /// date, [notGiven] as skipped; one command, one Undo.
  Future<CareOutcome<CareCommandResult>> resolveStack({
    required String entryId,
    List<String> given = const [],
    List<String> notGiven = const [],
  }) {
    return _run('stack', () async {
      final body = await _remote.postResolveStack(entryId, {
        'given': given,
        'not_given': notGiven,
        'source': 'care_item',
        'path': 'stack',
      });
      return _commandResult(entryId, body);
    });
  }

  /// Undo the command [undoToken] names, or the item's last one.
  Future<CareOutcome<CareCommandResult>> undo({
    required String entryId,
    String? undoToken,
  }) {
    return _run('undo', () async {
      final body = await _remote.postUndo(entryId, undoToken);
      return _commandResult(entryId, body);
    });
  }

  Future<CareOutcome<OccurrenceDetail>> fetchOccurrence({
    required String entryId,
    required String occurrenceId,
  }) {
    return _run('occurrence', () async {
      final body = await _remote.getOccurrence(entryId, occurrenceId);
      return occurrenceDetailFromJson(body);
    });
  }

  Future<CareOutcome<CareItemSchedule>> fetchCareItem(String entryId) {
    return _run('care_item', () async {
      return careItemScheduleFromJson(await _remote.getCareItem(entryId));
    });
  }

  Future<CareOutcome<List<CareItemSchedule>>> fetchCareItems({String? petId}) {
    return _run('care_items', () async {
      final rows = await _remote.getCareItems(petId: petId);
      return rows
          .where((row) => row['as_of'] is Map<String, dynamic>)
          .map(careItemScheduleFromJson)
          .toList(growable: false);
    });
  }

  CareCommandResult _commandResult(String entryId, Map<String, dynamic> body) {
    final entry = body['entry'];
    final occurrence = body['occurrence'];
    return CareCommandResult(
      entryId: entryId,
      occurrenceId: occurrence is Map<String, dynamic>
          ? occurrence['id'] as String?
          : body['id'] as String?,
      schedule: entry is Map<String, dynamic> && entry['as_of'] is Map
          ? careItemScheduleFromJson(entry)
          : null,
      undoToken: body['undo_token'] as String?,
      nextChoiceApplied: body['next_choice_applied'] as String?,
      nextDueDate: parseCalendarDate(body['next_due_date']),
      movedNextId: body['moved_next_id'] as String?,
      nextUnchanged: body['next_unchanged'] == true,
    );
  }

  Future<CareOutcome<T>> _run<T>(
    String action,
    Future<T> Function() call,
  ) async {
    try {
      return CareSucceeded(await call());
    } on CareHttpException catch (e) {
      final failure = mapCareHttpFailure(e);
      _log(action, failure, statusCode: e.statusCode);
      return CareFailed(failure);
    } on SessionExpiredException {
      const failure = CareNetworkFailure();
      _log(action, failure);
      return const CareFailed(failure);
    } on http.ClientException {
      const failure = CareNetworkFailure();
      _log(action, failure);
      return const CareFailed(failure);
    } on TimeoutException {
      const failure = CareNetworkFailure();
      _log(action, failure);
      return const CareFailed(failure);
    } on FormatException {
      const failure = CareUnknownFailure();
      _log(action, failure);
      return const CareFailed(failure);
    }
  }

  /// Error class and HTTP status only — no names, dates, notes or weights.
  void _log(String action, CareCommandFailure failure, {int? statusCode}) {
    developer.log(
      '$action failed: ${failure.runtimeType}'
      '${statusCode == null ? '' : ' (HTTP $statusCode)'}',
      name: 'care.completion',
    );
  }
}

/// HTTP answer → failure (§18.10, DN-9).
CareCommandFailure mapCareHttpFailure(CareHttpException e) {
  if (e.statusCode == 400) return CareValidationFailure(e.code ?? 'invalid');
  if (e.statusCode == 404) return const CareNotOpenFailure(gone: true);
  if (e.statusCode == 409) {
    return e.code == 'occurrence_not_open'
        ? const CareNotOpenFailure()
        : CareConflictFailure(e.code);
  }
  return CareUnknownFailure(e.statusCode);
}
