import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/pet_care/context/data/models/planned_absence_model.dart';

void main() {
  test('PlannedAbsenceModel parses timezone', () {
    final absence = PlannedAbsenceModel.fromJson({
      'id': 'a1',
      'user_id': 'u1',
      'starts_on': '2026-10-01',
      'ends_on': '2026-10-05',
      'status': 'active',
      'timezone': 'Europe/Paris',
      'pet_ids': ['p1'],
    });
    expect(absence.timezone, 'Europe/Paris');
  });
}
