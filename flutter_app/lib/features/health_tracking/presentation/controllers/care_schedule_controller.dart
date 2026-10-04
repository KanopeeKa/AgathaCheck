import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/command_outcome.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_issue.dart';
import '../../domain/entities/reschedule_occurrence_result.dart';
import '../providers/care_item_detail_refresh.dart';
import '../providers/health_issue_providers.dart';
import '../providers/health_providers.dart';
import '../providers/pet_event_view_providers.dart';

final careScheduleControllerProvider = Provider<CareScheduleController>((ref) {
  return CareScheduleController(ref);
});

/// Client authority for care schedule mutations (D19 / Package 8).
class CareScheduleController {
  CareScheduleController(this._ref);

  final Ref _ref;
  final Set<String> _inFlightKeys = {};

  String _occurrenceCommandKey(String entryId, String occurrenceId) =>
      '$entryId:$occurrenceId';

  Future<T?> _runGuarded<T>(String key, Future<T> Function() action) async {
    if (_inFlightKeys.contains(key)) return null;
    _inFlightKeys.add(key);
    try {
      return await action();
    } finally {
      _inFlightKeys.remove(key);
    }
  }

  Future<HealthEntry?> getEntry(String entryId) {
    return _ref.read(healthRepositoryProvider).getEntry(entryId);
  }

  void invalidateEntryHistory(String entryId) {
    _ref.invalidate(entryHistoryProvider(entryId));
  }

  Future<CommandOutcome> _reconcileAfterCommit(
    String entryId, {
    String? absenceId,
  }) async {
    try {
      invalidateCareScheduleProviders(_ref, entryId, absenceId: absenceId);
      await _ref.read(healthEntriesNotifierProvider.notifier).refresh();
      final entriesAsync = _ref.read(healthEntriesNotifierProvider);
      final refreshFailed =
          entriesAsync.hasError && entriesAsync.valueOrNull != null;
      return CommandOutcome(committed: true, refreshFailed: refreshFailed);
    } on StateError {
      return const CommandOutcome(committed: true);
    }
  }

  Future<CommandOutcome?> completeOccurrence(
    String entryId,
    String occurrenceId, {
    DateTime? completedOn,
    bool skipEarlierMissed = false,
    String notes = '',
  }) {
    return _runGuarded(_occurrenceCommandKey(entryId, occurrenceId), () async {
      await _ref.read(healthRepositoryProvider).completeOccurrence(
        entryId,
        occurrenceId,
        notes: notes,
        completedOn: completedOn,
        skipEarlierMissed: skipEarlierMissed,
      );
      return _reconcileAfterCommit(entryId);
    });
  }

  Future<CommandOutcome?> skipOccurrence(
    String entryId,
    String occurrenceId, {
    String? absenceId,
    String notes = '',
  }) {
    return _runGuarded(_occurrenceCommandKey(entryId, occurrenceId), () async {
      await _ref.read(healthRepositoryProvider).skipOccurrence(
        entryId,
        occurrenceId,
        notes: notes,
      );
      return _reconcileAfterCommit(entryId, absenceId: absenceId);
    });
  }

  Future<CommandOutcome?> skipAllMissedOccurrences(String entryId) {
    return _runGuarded('skip-missed:$entryId', () async {
      await _ref.read(healthRepositoryProvider).skipMissedOccurrences(entryId);
      return _reconcileAfterCommit(entryId);
    });
  }

  Future<CommandOutcome?> undoOccurrence(
    String entryId,
    String occurrenceId, {
    String? absenceId,
  }) {
    return _runGuarded(_occurrenceCommandKey(entryId, occurrenceId), () async {
      await _ref.read(healthRepositoryProvider).undoOccurrence(
        entryId,
        occurrenceId,
      );
      return _reconcileAfterCommit(entryId, absenceId: absenceId);
    });
  }

  Future<({RescheduleOccurrenceResult result, CommandOutcome outcome})?>
  rescheduleOccurrence(
    String entryId,
    String occurrenceId,
    DateTime scheduledDate, {
    String? reasonCode,
    String? absenceId,
  }) {
    return _runGuarded(_occurrenceCommandKey(entryId, occurrenceId), () async {
      final result = await _ref.read(healthRepositoryProvider).rescheduleOccurrence(
        entryId,
        occurrenceId,
        scheduledDate,
        reasonCode: reasonCode,
      );
      final outcome = await _reconcileAfterCommit(
        entryId,
        absenceId: absenceId,
      );
      return (result: result, outcome: outcome);
    });
  }

  Future<CommandOutcome?> completeWeightOccurrence({
    required String petId,
    required String entryId,
    required String occurrenceId,
    required double weightKg,
    required DateTime date,
    String notes = '',
  }) {
    return _runGuarded(_occurrenceCommandKey(entryId, occurrenceId), () async {
      await _ref.read(healthRepositoryProvider).completeWeightOccurrence(
        petId: petId,
        entryId: entryId,
        occurrenceId: occurrenceId,
        weightKg: weightKg,
        date: date,
        notes: notes,
      );
      return _reconcileAfterCommit(entryId);
    });
  }

  Future<CommandOutcome?> updateOccurrenceDetails(
    String entryId,
    String occurrenceId, {
    required String notes,
    String? providerContactId,
    String? providerTypedName,
    List<({String name, Uint8List bytes})> pendingDocuments = const [],
  }) {
    return _runGuarded(
      'details:$entryId:$occurrenceId',
      () async {
        await _ref.read(healthRepositoryProvider).updateOccurrenceNotes(
          entryId,
          occurrenceId,
          notes,
          providerContactId: providerContactId,
          providerTypedName: providerTypedName,
        );
        final dataSource = _ref.read(healthDataSourceProvider);
        for (final doc in pendingDocuments) {
          await dataSource.uploadPhoto(
            entryId,
            doc.bytes,
            doc.name,
            occurrenceId: occurrenceId,
          );
        }
        _ref.invalidate(healthEntryPhotosProvider(entryId));
        return _reconcileAfterCommit(entryId);
      },
    );
  }

  Future<CommandOutcome> linkHealthIssue(
    String petId,
    String issueId,
    String entryId,
  ) async {
    await _ref
        .read(healthIssueNotifierProvider(petId).notifier)
        .linkEvent(issueId, entryId);
    return _reconcileAfterCommit(entryId);
  }

  Future<CommandOutcome> createAndLinkHealthIssue(
    String petId,
    HealthIssue draft,
    String entryId,
  ) async {
    final issue = draft.id.isEmpty
        ? draft.copyWith(id: const Uuid().v4())
        : draft;
    final notifier = _ref.read(healthIssueNotifierProvider(petId).notifier);
    await notifier.create(issue);
    await notifier.linkEvent(issue.id, entryId);
    return _reconcileAfterCommit(entryId);
  }

  Future<CommandOutcome> unlinkHealthIssue(
    String petId,
    String issueId,
    String entryId,
  ) async {
    await _ref
        .read(healthIssueNotifierProvider(petId).notifier)
        .unlinkEvent(issueId, entryId);
    return _reconcileAfterCommit(entryId);
  }
}
