import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_establishment.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/care_establishment_helpers.dart';

HealthEntry _entry({
  required String id,
  required String name,
  required HealthFrequency frequency,
}) {
  return HealthEntry(
    id: id,
    petId: 'pet-1',
    name: name,
    type: HealthEntryType.preventive,
    frequency: frequency,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime(2026, 10, 1),
  );
}

void main() {
  test('establishedRhythmEntryIds matches weight monitoring rhythms only', () {
    final weightRhythm = _entry(
      id: 'weight-1',
      name: 'Weight',
      frequency: HealthFrequency.weekly,
    ).copyWith(careFamily: CareFamily.weightMonitoring);
    final fleaRhythm = _entry(
      id: 'flea-1',
      name: 'Flea',
      frequency: HealthFrequency.monthly,
    ).copyWith(careFamily: CareFamily.parasitePrevention);
    final establishments = [
      CareEstablishment(
        id: 'est-1',
        careFamily: CareFamily.weightMonitoring,
        healthEntryId: 'weight-1',
        establishedAt: DateTime(2026, 1, 1),
        policyVersion: 'weight_v1',
      ),
      CareEstablishment(
        id: 'est-2',
        careFamily: CareFamily.parasitePrevention,
        healthEntryId: 'flea-1',
        establishedAt: DateTime(2026, 1, 1),
        policyVersion: 'weight_v1',
      ),
    ];

    final ids = establishedRhythmEntryIds(establishments, [
      weightRhythm,
      fleaRhythm,
    ]);

    expect(ids, {'weight-1'});
  });

  test(
    'establishedRhythmEntryIds ignores establishments for missing entries',
    () {
      final rhythm = _entry(
        id: 'weight-1',
        name: 'Weight',
        frequency: HealthFrequency.weekly,
      ).copyWith(careFamily: CareFamily.weightMonitoring);
      final establishments = [
        CareEstablishment(
          id: 'est-1',
          careFamily: CareFamily.weightMonitoring,
          healthEntryId: 'other-entry',
          establishedAt: DateTime(2026, 1, 1),
          policyVersion: 'weight_v1',
        ),
      ];

      expect(establishedRhythmEntryIds(establishments, [rhythm]), isEmpty);
    },
  );
}
