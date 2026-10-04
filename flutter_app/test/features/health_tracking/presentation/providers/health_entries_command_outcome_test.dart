import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/command_outcome.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';

import '../../../../helpers/fakes.dart';
import 'health_entries_test_support.dart';

void main() {
  late FakeHealthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeHealthRepository(entries: [testHealthEntry('e1')]);
    container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        healthRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pumpNotifier() async {
    await container.read(healthEntriesNotifierProvider.future);
  }

  test(
    'CRUD commands return refreshFailed without throwing after commit',
    () async {
      await pumpNotifier();
      final notifier = container.read(healthEntriesNotifierProvider.notifier);
      repository.failNextGetEntries = true;

      final created = await notifier.create(testHealthEntry('new'));
      expect(
        created,
        const CommandOutcome(committed: true, refreshFailed: true),
      );
      expect(repository.createCallCount, 1);
      expect(container.read(healthEntriesNotifierProvider).hasValue, isTrue);

      repository.failNextGetEntries = true;
      final updated = await notifier.updateEntry(testHealthEntry('e1'));
      expect(updated.refreshFailed, isTrue);

      repository.failNextGetEntries = true;
      final deleted = await notifier.delete('e1');
      expect(deleted.refreshFailed, isTrue);
    },
  );

  test('command failure still throws before refresh', () async {
    await pumpNotifier();
    final notifier = container.read(healthEntriesNotifierProvider.notifier);
    repository.throwOnDelete = true;
    await expectLater(notifier.delete('e1'), throwsA(isException));
    expect(repository.getEntriesCallCount, 1);
  });

  test(
    'markTaken and undoComplete report refreshFailed after successful commit',
    () async {
      await pumpNotifier();
      final notifier = container.read(healthEntriesNotifierProvider.notifier);
      repository.failNextGetEntries = true;

      final taken = await notifier.markTaken('e1');
      expect(taken.refreshFailed, isTrue);
      expect(repository.completeOccurrenceCallCount, 1);

      repository.failNextGetEntries = true;
      final undone = await notifier.undoComplete('e1');
      expect(undone.refreshFailed, isTrue);
      expect(repository.unmarkDoneCallCount, 1);
    },
  );

  test('event lifecycle commands survive refresh failure', () async {
    await pumpNotifier();
    final notifier = container.read(healthEntriesNotifierProvider.notifier);
    repository.failNextGetEntries = true;

    expect(
      await notifier.closeEvent('e1'),
      const CommandOutcome(committed: true, refreshFailed: true),
    );
    repository.failNextGetEntries = true;
    expect(
      await notifier.reopenEvent('e1'),
      const CommandOutcome(committed: true, refreshFailed: true),
    );
  });

  test('pause and resume commands survive refresh failure', () async {
    await pumpNotifier();
    final notifier = container.read(healthEntriesNotifierProvider.notifier);
    repository.failNextGetEntries = true;

    expect(
      await notifier.pauseCareItem('e1'),
      const CommandOutcome(committed: true, refreshFailed: true),
    );
    repository.failNextGetEntries = true;
    expect(
      await notifier.resumeCareItem('e1'),
      const CommandOutcome(committed: true, refreshFailed: true),
    );
  });

  test('unmarkDone survives refresh failure', () async {
    await pumpNotifier();
    final notifier = container.read(healthEntriesNotifierProvider.notifier);
    repository.failNextGetEntries = true;

    expect(
      await notifier.unmarkDone('e1'),
      const CommandOutcome(committed: true, refreshFailed: true),
    );
  });
}
