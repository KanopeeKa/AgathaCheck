import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';

class _FakeHealthEntriesNotifier extends HealthEntriesNotifier {
  _FakeHealthEntriesNotifier(this._entries);
  final List<HealthEntry> _entries;
  @override
  Future<List<HealthEntry>> build() async => _entries;
}

HealthEntry _entry(String id, String petId) => HealthEntry(
      id: id,
      petId: petId,
      name: 'Entry $id',
      type: HealthEntryType.medication,
      frequency: HealthFrequency.monthly,
      startDate: DateTime(2025, 1, 1),
      nextDueDate: DateTime(2025, 2, 1),
    );

void main() {
  test('petHealthEntriesByIdProvider returns only the given pet\'s entries',
      () async {
    final entries = [
      _entry('a', 'pet-1'),
      _entry('b', 'pet-2'),
      _entry('c', 'pet-1'),
    ];
    final container = ProviderContainer(overrides: [
      healthEntriesNotifierProvider
          .overrideWith(() => _FakeHealthEntriesNotifier(entries)),
    ]);
    addTearDown(container.dispose);

    // Wait for the global list to load.
    await container.read(healthEntriesNotifierProvider.future);

    final pet1 = container.read(petHealthEntriesByIdProvider('pet-1')).value!;
    expect(pet1.map((e) => e.id), ['a', 'c']);

    final pet2 = container.read(petHealthEntriesByIdProvider('pet-2')).value!;
    expect(pet2.map((e) => e.id), ['b']);

    final none = container.read(petHealthEntriesByIdProvider('pet-3')).value!;
    expect(none, isEmpty);
  });
}
