import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_repository.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';

import '../../../../helpers/fakes.dart';
import 'health_entries_test_support.dart';

class _OutOfOrderFetchRepository implements HealthRepository {
  _OutOfOrderFetchRepository(this._handlers);

  final List<Future<List<HealthEntry>> Function()> _handlers;
  var _index = 0;

  @override
  Future<List<HealthEntry>> getEntries({String? petId, HealthEntryType? type}) {
    final handler = _handlers[_index.clamp(0, _handlers.length - 1)];
    _index++;
    return handler();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'overlapping fetches drop superseded generations (newest wins)',
    () async {
      final slowCompleter = Completer<List<HealthEntry>>();
      final repository = _OutOfOrderFetchRepository([
        () async => [testHealthEntry('initial')],
        () => slowCompleter.future,
        () async => [testHealthEntry('newest')],
      ]);

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          healthRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(healthEntriesNotifierProvider.future);

      final notifier = container.read(healthEntriesNotifierProvider.notifier);
      final slowRefresh = notifier.refresh();
      final fastRefresh = notifier.refresh();

      await fastRefresh;
      expect(
        container.read(healthEntriesNotifierProvider).value!.single.id,
        'newest',
      );

      slowCompleter.complete([testHealthEntry('stale')]);
      await slowRefresh;

      expect(
        container.read(healthEntriesNotifierProvider).value!.single.id,
        'newest',
      );
    },
  );
}
