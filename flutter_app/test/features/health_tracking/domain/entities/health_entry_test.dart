import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';

void main() {
  group('HealthEntry', () {
    final now = DateTime.now();

    HealthEntry createEntry({
      DateTime? nextDueDate,
      HealthFrequency frequency = HealthFrequency.daily,
    }) {
      return HealthEntry(
        id: 'test-id',
        petId: 'pet-1',
        name: 'Heartgard',
        type: HealthEntryType.medication,
        dosage: '1 tablet',
        frequency: frequency,
        startDate: DateTime(2025, 1, 1),
        nextDueDate: nextDueDate ?? now.add(const Duration(days: 1)),
        notes: 'Give with food',
      );
    }

    test('creates instance with required fields', () {
      final entry = createEntry();
      expect(entry.id, 'test-id');
      expect(entry.petId, 'pet-1');
      expect(entry.name, 'Heartgard');
      expect(entry.type, HealthEntryType.medication);
      expect(entry.dosage, '1 tablet');
      expect(entry.frequency, HealthFrequency.daily);
      expect(entry.notes, 'Give with food');
    });

    test('isOverdue returns true when past due', () {
      final entry =
          createEntry(nextDueDate: now.subtract(const Duration(days: 1)));
      expect(entry.isOverdue, isTrue);
    });

    test('isOverdue returns false when not past due', () {
      final entry =
          createEntry(nextDueDate: now.add(const Duration(hours: 1)));
      expect(entry.isOverdue, isFalse);
    });

    test('isDueToday returns true when due today', () {
      final todayEntry = createEntry(
          nextDueDate: DateTime(now.year, now.month, now.day, 23, 59));
      expect(todayEntry.isDueToday, isTrue);
    });

    test('isDueToday returns false when due another day', () {
      final tomorrowEntry =
          createEntry(nextDueDate: now.add(const Duration(days: 2)));
      expect(tomorrowEntry.isDueToday, isFalse);
    });

    test('isDueSoon returns true when due within 24 hours', () {
      final entry =
          createEntry(nextDueDate: now.add(const Duration(hours: 12)));
      expect(entry.isDueSoon, isTrue);
    });

    test('isDueSoon returns false when overdue', () {
      final entry =
          createEntry(nextDueDate: now.subtract(const Duration(days: 1)));
      expect(entry.isDueSoon, isFalse);
    });

    test('isCompleted true when completedOn is set for once entry', () {
      final entry = HealthEntry(
        id: 'test-id',
        petId: 'pet-1',
        name: 'Heartgard',
        type: HealthEntryType.medication,
        frequency: HealthFrequency.once,
        startDate: DateTime(2025, 1, 1),
        nextDueDate: null,
        completedOn: DateTime(2025, 1, 15),
      );
      expect(entry.isCompleted, isTrue);
    });

    test('isCompleted true for once entry at the 9999 sentinel date', () {
      final entry = createEntry(
        frequency: HealthFrequency.once,
        nextDueDate: DateTime(9999, 12, 31),
      );
      expect(entry.isCompleted, isTrue);
    });

    test('isCompleted false for once entry with a real due date', () {
      final entry = createEntry(
        frequency: HealthFrequency.once,
        nextDueDate: now.subtract(const Duration(days: 1)),
      );
      expect(entry.isCompleted, isFalse);
    });

    test('isCompleted false for recurring entry even at sentinel date', () {
      final entry = createEntry(
        frequency: HealthFrequency.monthly,
        nextDueDate: DateTime(9999, 12, 31),
      );
      expect(entry.isCompleted, isFalse);
    });

    test('completed once entry is not overdue despite past start date', () {
      final entry = createEntry(
        frequency: HealthFrequency.once,
        nextDueDate: DateTime(9999, 12, 31),
      );
      expect(entry.isOverdue, isFalse);
    });

    test('overdue recurring entry clears overdue once due date advances forward',
        () {
      final overdue = createEntry(
        frequency: HealthFrequency.weekly,
        nextDueDate: now.subtract(const Duration(days: 10)),
      );
      expect(overdue.isOverdue, isTrue);

      // Marking complete advances next_due_date into the future (server-side),
      // which is what clears the overdue state in the UI.
      final advanced =
          overdue.copyWith(nextDueDate: now.add(const Duration(days: 4)));
      expect(advanced.isOverdue, isFalse);
      expect(advanced.isCompleted, isFalse);
    });

    test('copyWith creates modified copy', () {
      final entry = createEntry();
      final copy = entry.copyWith(name: 'NexGard', dosage: '2 tablets');
      expect(copy.name, 'NexGard');
      expect(copy.dosage, '2 tablets');
      expect(copy.id, entry.id);
      expect(copy.type, entry.type);
    });

    test('equality based on id', () {
      final entry1 = createEntry();
      final entry2 = createEntry();
      expect(entry1, equals(entry2));
      expect(entry1.hashCode, equals(entry2.hashCode));
    });

    test('inequality for different ids', () {
      final entry1 = createEntry();
      final entry2 = entry1.copyWith(id: 'different-id');
      expect(entry1, isNot(equals(entry2)));
    });
  });

  group('HealthEntryType', () {
    test('label returns human-readable text', () {
      expect(HealthEntryType.medication.label, 'Medication');
      expect(HealthEntryType.preventive.label, 'Preventive');
      expect(HealthEntryType.vetVisit.label, 'Vet Visit');
    });
  });

  group('HealthFrequency', () {
    test('label returns human-readable text', () {
      expect(HealthFrequency.daily.label, 'Day');
      expect(HealthFrequency.weekly.label, 'Week');
      expect(HealthFrequency.monthly.label, 'Month');
      expect(HealthFrequency.custom.label, 'Custom');
    });
  });
}
