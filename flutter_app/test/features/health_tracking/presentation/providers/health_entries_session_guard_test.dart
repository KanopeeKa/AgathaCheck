import 'dart:async' show Completer, unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/auth/data/auth_service.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_repository.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';

import '../../../../helpers/fakes.dart';
import 'health_entries_test_support.dart';

class _DelayedLogoutRepository implements HealthRepository {
  final _staleCompleter = Completer<List<HealthEntry>>();
  final _activeSessionBlocker = Completer<List<HealthEntry>>();
  var _callCount = 0;

  @override
  Future<List<HealthEntry>> getEntries({String? petId, HealthEntryType? type}) {
    _callCount++;
    if (_callCount == 1) {
      return _staleCompleter.future;
    }
    return _activeSessionBlocker.future;
  }

  void completeStale(List<HealthEntry> entries) {
    if (!_staleCompleter.isCompleted) {
      _staleCompleter.complete(entries);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('fetch started before logout does not write after session bump', () async {
    final repository = _DelayedLogoutRepository();
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        healthRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    // Start the initial session fetch (will stay pending until [completeStale]).
    unawaited(container.read(healthEntriesNotifierProvider.future));

    container.read(authProvider.notifier).state = const AuthState();

    repository.completeStale([testHealthEntry('after-logout')]);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final async = container.read(healthEntriesNotifierProvider);
    expect(async.hasValue, isFalse);
    expect(async.isLoading, isTrue);
    expect(async.valueOrNull, isNull);
  });

  test(
    'user switch clears in-flight data before the next user loads',
    () async {
      final repository = FakeHealthRepository(
        entries: [testHealthEntry('user-a')],
      );
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          healthRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(healthEntriesNotifierProvider.future);
      expect(
        container.read(healthEntriesNotifierProvider).value!.single.id,
        'user-a',
      );

      repository.entries = [testHealthEntry('user-b')];
      container.read(authProvider.notifier).state = loggedInAuthState.copyWith(
        user: AuthUser(
          id: 'other-user',
          email: 'other@example.com',
          firstName: 'Other',
          lastName: 'User',
        ),
      );

      await container.read(healthEntriesNotifierProvider.future);
      expect(
        container.read(healthEntriesNotifierProvider).value!.single.id,
        'user-b',
      );
    },
  );
}
