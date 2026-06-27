import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/data/services/pet_report_profile_section.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_entry.dart';

WeightEntry _entry(String id, DateTime date, double weight) =>
    WeightEntry(id: id, petId: 'pet-1', date: date, weight: weight);

void main() {
  group('PetProfileSectionBuilder.currentWeightFromEntries', () {
    test('returns fallback when there are no entries', () {
      expect(
        PetProfileSectionBuilder.currentWeightFromEntries(const [], 12.5),
        12.5,
      );
    });

    test('returns null fallback when there are no entries and no profile weight',
        () {
      expect(
        PetProfileSectionBuilder.currentWeightFromEntries(const [], null),
        isNull,
      );
    });

    test('returns the most recent entry by date regardless of list order', () {
      final entries = [
        _entry('w3', DateTime(2025, 6, 1), 25.0),
        _entry('w1', DateTime(2025, 4, 1), 24.0),
        _entry('w2', DateTime(2025, 5, 1), 24.5),
      ];

      expect(
        PetProfileSectionBuilder.currentWeightFromEntries(entries, 20.0),
        25.0,
      );
    });

    test('handles API descending date order (newest first)', () {
      final entries = [
        _entry('w2', DateTime(2025, 6, 1), 25.0),
        _entry('w1', DateTime(2025, 4, 1), 24.0),
      ];

      expect(
        PetProfileSectionBuilder.currentWeightFromEntries(entries, 20.0),
        25.0,
      );
    });
  });
}
