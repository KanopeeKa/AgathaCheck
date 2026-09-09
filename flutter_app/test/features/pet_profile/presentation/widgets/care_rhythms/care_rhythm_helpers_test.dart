import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_establishment.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/care_rhythms/care_rhythm_helpers.dart';

HealthEntry _entry({
  required String id,
  required String name,
  required HealthFrequency frequency,
  DateTime? repeatEndDate,
}) {
  return HealthEntry(
    id: id,
    petId: 'pet-1',
    name: name,
    type: HealthEntryType.preventive,
    frequency: frequency,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime(2026, 10, 1),
    repeatEndDate: repeatEndDate,
  );
}

void main() {
  test('filterCareRhythms keeps only recurring entries', () {
    final recurring = _entry(
      id: 'r1',
      name: 'Flea',
      frequency: HealthFrequency.monthly,
    );
    final oneTime = _entry(
      id: 'o1',
      name: 'Groom',
      frequency: HealthFrequency.once,
    );

    final result = filterCareRhythms([oneTime, recurring]);

    expect(result, hasLength(1));
    expect(result.first.id, 'r1');
  });

  test('filterCareRhythms sorts active before closed then by name', () {
    final closed = _entry(
      id: 'closed',
      name: 'Zebra dose',
      frequency: HealthFrequency.monthly,
      repeatEndDate: DateTime(2020, 1, 1),
    );
    final activeB = _entry(
      id: 'b',
      name: 'Bravo tick',
      frequency: HealthFrequency.weekly,
    );
    final activeA = _entry(
      id: 'a',
      name: 'Alpha flea',
      frequency: HealthFrequency.weekly,
    );

    final result = filterCareRhythms([closed, activeB, activeA]);

    expect(result.map((e) => e.id).toList(), ['a', 'b', 'closed']);
  });

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

    final ids = establishedRhythmEntryIds(
      establishments,
      [weightRhythm, fleaRhythm],
    );

    expect(ids, {'weight-1'});
  });

  test('establishedRhythmEntryIds ignores establishments for missing rhythms', () {
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
  });
}
