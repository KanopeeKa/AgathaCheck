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

HealthEntry _entry({
  required String id,
  DateTime? nextDueDate,
  HealthFrequency frequency = HealthFrequency.monthly,
  DateTime? completedOn,
  int remindDaysBefore = 1,
}) => HealthEntry(
  id: id,
  petId: 'pet-1',
  name: 'Entry $id',
  type: HealthEntryType.medication,
  frequency: frequency,
  startDate: DateTime(2025, 1, 1),
  nextDueDate: nextDueDate,
  completedOn: completedOn,
  remindDaysBefore: remindDaysBefore,
);

void main() {
  group('isEntryDueOrOverdue', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    test('returns true when overdue', () {
      final entry = _entry(
        id: 'a',
        nextDueDate: today.subtract(const Duration(days: 1)),
      );
      expect(isEntryDueOrOverdue(entry), isTrue);
    });

    test('returns true when due today', () {
      final entry = _entry(id: 'a', nextDueDate: today);
      expect(isEntryDueOrOverdue(entry), isTrue);
    });

    test('returns true when due within remindDaysBefore window', () {
      final entry = _entry(
        id: 'a',
        nextDueDate: today.add(const Duration(days: 2)),
        remindDaysBefore: 3,
      );
      expect(isEntryDueOrOverdue(entry), isTrue);
    });

    test('returns false when due outside remindDaysBefore window', () {
      final entry = _entry(
        id: 'a',
        nextDueDate: today.add(const Duration(days: 5)),
        remindDaysBefore: 3,
      );
      expect(isEntryDueOrOverdue(entry), isFalse);
    });

    test('returns false when due in the future', () {
      final entry = _entry(
        id: 'a',
        nextDueDate: today.add(const Duration(days: 2)),
      );
      expect(isEntryDueOrOverdue(entry), isFalse);
    });

    test('returns false when completed once entry', () {
      final entry = _entry(
        id: 'a',
        frequency: HealthFrequency.once,
        nextDueDate: today,
        completedOn: today,
      );
      expect(isEntryDueOrOverdue(entry), isFalse);
    });
  });

  test(
    'hasDueOrOverdueEventsProvider is true when any entry is due or overdue',
    () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final entries = [
        _entry(id: 'a', nextDueDate: today.add(const Duration(days: 5))),
        _entry(id: 'b', nextDueDate: today.subtract(const Duration(days: 1))),
      ];
      final container = ProviderContainer(
        overrides: [
          healthEntriesNotifierProvider.overrideWith(
            () => _FakeHealthEntriesNotifier(entries),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(healthEntriesNotifierProvider.future);
      expect(container.read(hasDueOrOverdueEventsProvider), isTrue);
    },
  );

  test(
    'hasDueOrOverdueEventsProvider is false when no due or overdue entries',
    () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final entries = [
        _entry(id: 'a', nextDueDate: today.add(const Duration(days: 5))),
      ];
      final container = ProviderContainer(
        overrides: [
          healthEntriesNotifierProvider.overrideWith(
            () => _FakeHealthEntriesNotifier(entries),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(healthEntriesNotifierProvider.future);
      expect(container.read(hasDueOrOverdueEventsProvider), isFalse);
    },
  );
}
