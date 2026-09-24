import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';

import '../../../../helpers/fakes.dart';

HealthEntry _entry(String id, String petId) => HealthEntry(
  id: id,
  petId: petId,
  name: 'Entry $id',
  type: HealthEntryType.medication,
  frequency: HealthFrequency.monthly,
  startDate: DateTime(2025, 1, 1),
  nextDueDate: DateTime(2025, 2, 1),
);

class _MutableHealthEntriesNotifier extends HealthEntriesNotifier {
  _MutableHealthEntriesNotifier(this._entries);

  List<HealthEntry> _entries;

  void replaceEntries(List<HealthEntry> entries) {
    _entries = entries;
    state = AsyncData(entries);
  }

  @override
  Future<List<HealthEntry>> build() async {
    ref.watch(authProvider);
    return _entries;
  }
}

void main() {
  test(
    'petHealthEntriesByIdProvider reflects global notifier mutations',
    () async {
      final notifier = _MutableHealthEntriesNotifier([_entry('a', 'pet-1')]);
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          healthEntriesNotifierProvider.overrideWith(() => notifier),
        ],
      );
      addTearDown(container.dispose);

      await container.read(healthEntriesNotifierProvider.future);
      expect(
        container.read(petHealthEntriesByIdProvider('pet-1')).value!.length,
        1,
      );

      notifier.replaceEntries([
        _entry('a', 'pet-1'),
        _entry('b', 'pet-1'),
        _entry('c', 'pet-2'),
      ]);

      final pet1 = container.read(petHealthEntriesByIdProvider('pet-1')).value!;
      expect(pet1.map((e) => e.id), ['a', 'b']);
    },
  );

  test('healthEntriesNotifier build watches authProvider', () async {
    var buildCount = 0;
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        healthEntriesNotifierProvider.overrideWith(() {
          return _BuildCountingNotifier(() => buildCount++);
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(healthEntriesNotifierProvider.future);
    expect(buildCount, 1);

    container.read(authProvider.notifier).state = const AuthState();
    await container.read(healthEntriesNotifierProvider.future);
    expect(buildCount, greaterThan(1));
  });
}

class _BuildCountingNotifier extends HealthEntriesNotifier {
  _BuildCountingNotifier(this.onBuild);

  final void Function() onBuild;

  @override
  Future<List<HealthEntry>> build() async {
    ref.watch(authProvider);
    onBuild();
    return [];
  }
}
