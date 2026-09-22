import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_family_definition.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/domain/services/care_entry_filter.dart';

void main() {
  group('effectiveCareFamilyForFilter', () {
    test('uses persisted care family when present', () {
      final entry = HealthEntry(
        id: '1',
        petId: 'p1',
        name: 'Vaccine',
        type: HealthEntryType.other,
        dosage: '',
        frequency: HealthFrequency.once,
        startDate: DateTime(2025, 1, 1),
        careFamily: CareFamily.vaccination,
      );

      expect(effectiveCareFamilyForFilter(entry), CareFamily.vaccination);
    });

    test('falls back to legacy type default when family is null', () {
      final entry = HealthEntry(
        id: '1',
        petId: 'p1',
        name: 'Tablet',
        type: HealthEntryType.medication,
        dosage: '',
        frequency: HealthFrequency.daily,
        startDate: DateTime(2025, 1, 1),
      );

      expect(effectiveCareFamilyForFilter(entry), CareFamily.medication);
    });
  });

  group('filterGroupForEntry', () {
    test('maps medication to prevention group', () {
      final entry = HealthEntry(
        id: '1',
        petId: 'p1',
        name: 'Tablet',
        type: HealthEntryType.medication,
        dosage: '',
        frequency: HealthFrequency.daily,
        startDate: DateTime(2025, 1, 1),
      );

      expect(filterGroupForEntry(entry), CareFilterGroup.prevention);
    });

    test('maps grooming family to lifestyle group', () {
      final entry = HealthEntry(
        id: '1',
        petId: 'p1',
        name: 'Brush',
        type: HealthEntryType.other,
        dosage: '',
        frequency: HealthFrequency.once,
        startDate: DateTime(2025, 1, 1),
        careFamily: CareFamily.grooming,
      );

      expect(filterGroupForEntry(entry), CareFilterGroup.lifestyle);
    });
  });
}
