import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';

void main() {
  group('HealthEntryTypeGroups', () {
    test('isHealthEvent is true for medication, preventive, vetVisit', () {
      expect(HealthEntryType.medication.isHealthEvent, isTrue);
      expect(HealthEntryType.preventive.isHealthEvent, isTrue);
      expect(HealthEntryType.vetVisit.isHealthEvent, isTrue);
    });

    test('isHealthEvent is false for other event type', () {
      expect(HealthEntryType.other.isHealthEvent, isFalse);
    });

    test('isOtherEvent is true for other type', () {
      expect(HealthEntryType.other.isOtherEvent, isTrue);
    });

    test('isOtherEvent is false for health event types', () {
      expect(HealthEntryType.medication.isOtherEvent, isFalse);
      expect(HealthEntryType.preventive.isOtherEvent, isFalse);
      expect(HealthEntryType.vetVisit.isOtherEvent, isFalse);
    });

    test('type sets partition all HealthEntryType values', () {
      for (final type in HealthEntryType.values) {
        expect(
          type.isHealthEvent ^ type.isOtherEvent,
          isTrue,
          reason: '$type must belong to exactly one pet-profile section',
        );
      }
    });

    test('other fallback label is Other', () {
      expect(HealthEntryType.other.label, 'Other');
    });
  });
}
