import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/domain/services/care_family_write.dart';

void main() {
  group('resolveCareFamilyForWrite', () {
    test('returns null for one-time entries without selection', () {
      expect(
        resolveCareFamilyForWrite(
          frequency: HealthFrequency.once,
          type: HealthEntryType.other,
        ),
        isNull,
      );
    });

    test('requires explicit family for recurring entries', () {
      expect(
        resolveCareFamilyForWrite(
          frequency: HealthFrequency.monthly,
          type: HealthEntryType.medication,
        ),
        CareFamily.medication,
      );
      expect(
        resolveCareFamilyForWrite(
          frequency: HealthFrequency.weekly,
          type: HealthEntryType.other,
          selected: CareFamily.weightMonitoring,
        ),
        CareFamily.weightMonitoring,
      );
    });

    test('defaults preventive to parasite prevention', () {
      expect(
        defaultCareFamilyForEntryType(HealthEntryType.preventive),
        CareFamily.parasitePrevention,
      );
    });
  });
}
