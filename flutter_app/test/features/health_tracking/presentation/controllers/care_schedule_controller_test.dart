import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/command_outcome.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/reschedule_occurrence_result.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_repository.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/controllers/care_schedule_controller.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';

import '../../../../helpers/fakes.dart';
import '../providers/health_entries_test_support.dart';

class _CareScheduleFakeRepository implements HealthRepository {
  _CareScheduleFakeRepository({List<HealthEntry>? entries})
    : entries = List<HealthEntry>.from(entries ?? [testHealthEntry('e1')]);

  List<HealthEntry> entries;
  var completeCalls = 0;
  var skipMissedCalls = 0;
  var rescheduleCalls = 0;
  var undoCalls = 0;
  bool failNextGetEntries = false;
  bool throwOnComplete = false;
  Duration? completeDelay;

  @override
  Future<List<HealthEntry>> getEntries({String? petId, HealthEntryType? type}) async {
    if (failNextGetEntries) {
      failNextGetEntries = false;
      throw Exception('refresh failed');
    }
    return List<HealthEntry>.from(entries);
  }

  @override
  Future<HealthOccurrence> completeOccurrence(
    String entryId,
    String occurrenceId, {
    String notes = '',
    DateTime? completedOn,
    bool skipEarlierMissed = false,
  }) async {
    completeCalls++;
    if (completeDelay != null) {
      await Future<void>.delayed(completeDelay!);
    }
    if (throwOnComplete) throw Exception('complete failed');
    return testOccurrence(entryId, id: occurrenceId);
  }

  @override
  Future<int> skipMissedOccurrences(String entryId) async {
    skipMissedCalls++;
    return 1;
  }

  @override
  Future<RescheduleOccurrenceResult> rescheduleOccurrence(
    String entryId,
    String occurrenceId,
    DateTime scheduledDate, {
    String? reasonCode,
  }) async {
    rescheduleCalls++;
    return RescheduleOccurrenceResult(
      occurrence: testOccurrence(entryId, id: occurrenceId),
      warnings: const [],
    );
  }

  @override
  Future<HealthOccurrence> undoOccurrence(
    String entryId,
    String occurrenceId,
  ) async {
    undoCalls++;
    return testOccurrence(entryId, id: occurrenceId);
  }

  @override
  Future<List<HealthOccurrence>> getOpenOccurrences(String entryId) async {
    return [testOccurrence(entryId)];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _CareScheduleFakeRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _CareScheduleFakeRepository();
    container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        healthRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() => container.dispose());

  CareScheduleController controller() =>
      container.read(careScheduleControllerProvider);

  Future<void> pumpStore() async {
    await container.read(healthEntriesNotifierProvider.future);
  }

  test('completeOccurrence returns refreshFailed after successful commit', () async {
    await pumpStore();
    repository.failNextGetEntries = true;
    final outcome = await controller().completeOccurrence(
      'e1',
      'occ-1',
      completedOn: DateTime(2025, 1, 2),
    );
    expect(outcome, const CommandOutcome(committed: true, refreshFailed: true));
    expect(repository.completeCalls, 1);
    expect(container.read(healthEntriesNotifierProvider).hasValue, isTrue);
  });

  test('completeOccurrence throws when command fails', () async {
    await pumpStore();
    repository.throwOnComplete = true;
    await expectLater(
      controller().completeOccurrence('e1', 'occ-1'),
      throwsA(isException),
    );
    expect(repository.completeCalls, 1);
  });

  test('duplicate complete calls are ignored while in flight', () async {
    await pumpStore();
    repository.completeDelay = const Duration(milliseconds: 50);
    final first = controller().completeOccurrence('e1', 'occ-1');
    final second = controller().completeOccurrence('e1', 'occ-1');
    final results = await Future.wait([first, second]);
    expect(results.where((r) => r == null).length, 1);
    expect(repository.completeCalls, 1);
  });

  test('skip missed and reschedule reconcile store', () async {
    await pumpStore();
    final skipped = await controller().skipAllMissedOccurrences('e1');
    expect(skipped?.committed, isTrue);
    expect(repository.skipMissedCalls, 1);

    final rescheduled = await controller().rescheduleOccurrence(
      'e1',
      'occ-1',
      DateTime(2025, 3, 1),
    );
    expect(rescheduled?.outcome.committed, isTrue);
    expect(repository.rescheduleCalls, 1);
  });

  test('dispose mid-command does not throw from controller', () async {
    await pumpStore();
    repository.completeDelay = const Duration(milliseconds: 100);
    final pending = controller().completeOccurrence('e1', 'occ-1');
    container.dispose();
    await expectLater(pending, completes);
  });
}
