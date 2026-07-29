import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_entry.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/weight_entry_sort.dart';

WeightEntry _entry(
  String id,
  DateTime date,
  double weight, {
  DateTime? createdAt,
}) =>
    WeightEntry(
      id: id,
      petId: 'pet-1',
      date: date,
      weight: weight,
      createdAt: createdAt,
    );

void main() {
  group('compareWeightEntriesChronological', () {
    test('orders by date then createdAt', () {
      final a = _entry(
        'a',
        DateTime(2026, 3, 1),
        10,
        createdAt: DateTime(2026, 3, 1, 9),
      );
      final b = _entry(
        'b',
        DateTime(2026, 3, 1),
        11,
        createdAt: DateTime(2026, 3, 1, 12),
      );
      final c = _entry('c', DateTime(2026, 4, 1), 12);

      expect(compareWeightEntriesChronological(a, b), lessThan(0));
      expect(compareWeightEntriesChronological(b, c), lessThan(0));
    });
  });

  group('sortWeightEntriesNewestFirst', () {
    test('returns newest date and latest createdAt first', () {
      final entries = [
        _entry(
          'old',
          DateTime(2026, 1, 1),
          9,
          createdAt: DateTime(2026, 1, 1, 8),
        ),
        _entry(
          'newer-day',
          DateTime(2026, 3, 1),
          11,
          createdAt: DateTime(2026, 3, 1, 8),
        ),
        _entry(
          'same-day-later',
          DateTime(2026, 3, 1),
          12,
          createdAt: DateTime(2026, 3, 1, 18),
        ),
      ];

      final sorted = sortWeightEntriesNewestFirst(entries);

      expect(sorted.map((e) => e.id).toList(), [
        'same-day-later',
        'newer-day',
        'old',
      ]);
    });
  });
}
