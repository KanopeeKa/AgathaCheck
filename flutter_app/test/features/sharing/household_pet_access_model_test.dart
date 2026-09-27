import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/sharing/data/models/household_pet_access_model.dart';

void main() {
  test('PetAccessOverviewModel parses household_access', () {
    final model = PetAccessOverviewModel.fromJson({
      'access': [
        {
          'id': 'a1',
          'pet_id': 'p1',
          'user_id': 'u2',
          'role': 'carer',
          'created_at': '2025-01-01T00:00:00Z',
        },
      ],
      'household_access': [
        {
          'user_id': 'u3',
          'access_tier': 'full_access',
          'is_organiser': true,
          'household_id': 'h1',
          'household_name': 'Home',
          'user': {'first_name': 'Sam', 'last_name': 'Lee'},
        },
      ],
    });

    expect(model.directAccess.length, 1);
    expect(model.householdAccess.length, 1);
    expect(model.householdAccess.first.displayName, 'Sam Lee');
    expect(model.householdAccess.first.tierLabel, contains('Organiser'));
  });
}
