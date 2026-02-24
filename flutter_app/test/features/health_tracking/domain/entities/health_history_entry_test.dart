import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/health_tracking/domain/entities/health_history_entry.dart';

void main() {
  group('HealthHistoryEntry', () {
    test('constructs with required fields', () {
      final entry = HealthHistoryEntry(
        id: 'h1',
        entryId: 'entry-1',
        takenAt: DateTime(2025, 1, 15),
      );

      expect(entry.id, 'h1');
      expect(entry.entryId, 'entry-1');
      expect(entry.takenAt, DateTime(2025, 1, 15));
      expect(entry.notes, '');
    });

    test('constructs with all fields', () {
      final entry = HealthHistoryEntry(
        id: 'h1',
        entryId: 'entry-1',
        takenAt: DateTime(2025, 1, 15),
        notes: 'Given with food',
      );

      expect(entry.notes, 'Given with food');
    });

    test('equality is based on id', () {
      final entry1 = HealthHistoryEntry(
        id: 'h1',
        entryId: 'entry-1',
        takenAt: DateTime(2025, 1, 15),
      );

      final entry2 = HealthHistoryEntry(
        id: 'h1',
        entryId: 'entry-2',
        takenAt: DateTime(2025, 2, 15),
        notes: 'Different notes',
      );

      expect(entry1, equals(entry2));
    });

    test('inequality when ids differ', () {
      final entry1 = HealthHistoryEntry(
        id: 'h1',
        entryId: 'entry-1',
        takenAt: DateTime(2025, 1, 15),
      );

      final entry2 = HealthHistoryEntry(
        id: 'h2',
        entryId: 'entry-1',
        takenAt: DateTime(2025, 1, 15),
      );

      expect(entry1, isNot(equals(entry2)));
    });

    test('hashCode is based on id', () {
      final entry1 = HealthHistoryEntry(
        id: 'h1',
        entryId: 'entry-1',
        takenAt: DateTime(2025, 1, 15),
      );

      final entry2 = HealthHistoryEntry(
        id: 'h1',
        entryId: 'entry-2',
        takenAt: DateTime(2025, 2, 15),
      );

      expect(entry1.hashCode, equals(entry2.hashCode));
    });

    test('hashCode differs for different ids', () {
      final entry1 = HealthHistoryEntry(
        id: 'h1',
        entryId: 'entry-1',
        takenAt: DateTime(2025, 1, 15),
      );

      final entry2 = HealthHistoryEntry(
        id: 'h2',
        entryId: 'entry-1',
        takenAt: DateTime(2025, 1, 15),
      );

      expect(entry1.hashCode, isNot(equals(entry2.hashCode)));
    });

    test('is not equal to non-HealthHistoryEntry', () {
      final entry = HealthHistoryEntry(
        id: 'h1',
        entryId: 'entry-1',
        takenAt: DateTime(2025, 1, 15),
      );

      expect(entry, isNot(equals('not an entry')));
    });

    test('identical entries are equal', () {
      final entry = HealthHistoryEntry(
        id: 'h1',
        entryId: 'entry-1',
        takenAt: DateTime(2025, 1, 15),
      );

      expect(entry, equals(entry));
    });
  });
}
