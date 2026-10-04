import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_repository.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';

import '../../../../helpers/fakes.dart';

HealthEntry _entry(String id) => HealthEntry(
  id: id,
  petId: 'pet-1',
  name: 'Entry $id',
  type: HealthEntryType.medication,
  frequency: HealthFrequency.monthly,
  startDate: DateTime(2025, 1, 1),
  nextDueDate: DateTime(2025, 2, 1),
);

class _SequenceHealthRepository implements HealthRepository {
  _SequenceHealthRepository(this._results);

  final List<List<HealthEntry>> _results;
  var callCount = 0;
  var getEntriesThrows = false;

  @override
  Future<List<HealthEntry>> getEntries({
    String? petId,
    HealthEntryType? type,
  }) async {
    final index = callCount.clamp(0, _results.length - 1);
    callCount++;
    await Future<void>.delayed(Duration.zero);
    if (getEntriesThrows) {
      throw Exception('refresh failed');
    }
    return _results[index];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'refresh keeps previous entries visible while loading (UIR-2 copyWithPrevious)',
    () async {
      final repository = _SequenceHealthRepository([
        [_entry('a')],
        [_entry('a'), _entry('b')],
      ]);
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          healthRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(healthEntriesNotifierProvider.future);
      expect(repository.callCount, 1);

      final notifier = container.read(healthEntriesNotifierProvider.notifier);
      final refreshFuture = notifier.refresh();

      final mid = container.read(healthEntriesNotifierProvider);
      expect(mid.isLoading, isTrue);
      expect(mid.hasValue, isTrue);
      expect(mid.value!.map((e) => e.id), ['a']);

      await refreshFuture;
      expect(container.read(healthEntriesNotifierProvider).value!.length, 2);
      expect(repository.callCount, 2);
    },
  );

  test(
    'refresh keeps previous entries on failure (AsyncError copyWithPrevious)',
    () async {
      final repository = _SequenceHealthRepository([
        [_entry('a')],
      ]);
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          healthRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(healthEntriesNotifierProvider.future);

      repository.getEntriesThrows = true;
      final notifier = container.read(healthEntriesNotifierProvider.notifier);
      await notifier.refresh();

      final after = container.read(healthEntriesNotifierProvider);
      expect(after.hasError, isTrue);
      expect(after.hasValue, isTrue);
      expect(after.value!.map((e) => e.id), ['a']);
    },
  );
}
