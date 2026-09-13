import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/domain/services/care_family_write.dart';

void main() {
  group('resolveCareFamilyForWrite', () {
    test('create requires explicit selection', () {
      expect(
        resolveCareFamilyForWrite(
          frequency: HealthFrequency.once,
          type: HealthEntryType.other,
          isCreate: true,
        ),
        isNull,
      );
      expect(
        resolveCareFamilyForWrite(
          frequency: HealthFrequency.monthly,
          type: HealthEntryType.medication,
          selected: CareFamily.vaccination,
          isCreate: true,
        ),
        CareFamily.vaccination,
      );
    });

    test('edit keeps null for uncategorised one-time entries', () {
      expect(
        resolveCareFamilyForWrite(
          frequency: HealthFrequency.once,
          type: HealthEntryType.other,
        ),
        isNull,
      );
    });

    test('edit keeps explicit selection for recurring entries', () {
      expect(
        resolveCareFamilyForWrite(
          frequency: HealthFrequency.monthly,
          type: HealthEntryType.medication,
          selected: CareFamily.weightMonitoring,
        ),
        CareFamily.weightMonitoring,
      );
      expect(
        resolveCareFamilyForWrite(
          frequency: HealthFrequency.weekly,
          type: HealthEntryType.other,
          existing: CareFamily.grooming,
        ),
        CareFamily.grooming,
      );
    });

    test('edit does not infer a default family', () {
      expect(
        resolveCareFamilyForWrite(
          frequency: HealthFrequency.monthly,
          type: HealthEntryType.medication,
        ),
        isNull,
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
