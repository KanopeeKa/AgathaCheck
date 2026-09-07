import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
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
}
