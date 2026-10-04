import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_repository.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';

import '../../../../helpers/fakes.dart';
import 'health_entries_test_support.dart';

class _StaleResurrectRepository implements HealthRepository {
  _StaleResurrectRepository()
    : entries = [testHealthEntry('keep'), testHealthEntry('deleted')];

  List<HealthEntry> entries;
  final _staleGate = Completer<void>();
  var _getEntriesCallCount = 0;

  @override
  Future<List<HealthEntry>> getEntries({
    String? petId,
    HealthEntryType? type,
  }) async {
    _getEntriesCallCount++;
    if (_getEntriesCallCount == 2) {
      await _staleGate.future;
      return [testHealthEntry('keep'), testHealthEntry('deleted')];
    }
    return List<HealthEntry>.from(entries);
  }

  @override
  Future<void> deleteEntry(String id) async {
    entries.removeWhere((e) => e.id == id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('stale in-flight fetch cannot resurrect a deleted entry', () async {
    final repository = _StaleResurrectRepository();
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        healthRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(healthEntriesNotifierProvider.future);

    final notifier = container.read(healthEntriesNotifierProvider.notifier);
    final staleRefresh = notifier.refresh();

    await Future<void>.delayed(Duration.zero);
    final deleteOutcome = await notifier.delete('deleted');
    expect(deleteOutcome.committed, isTrue);
    expect(
      container.read(healthEntriesNotifierProvider).value!.map((e) => e.id),
      ['keep'],
    );

    repository._staleGate.complete();
    await staleRefresh;

    expect(
      container.read(healthEntriesNotifierProvider).value!.map((e) => e.id),
      ['keep'],
    );
  });
}
