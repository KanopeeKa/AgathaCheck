import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/data/models/care_establishment_model.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';

void main() {
  test('fromJson parses weight monitoring establishment DTO', () {
    final model = CareEstablishmentModel.fromJson({
      'id': 'est-1',
      'care_family': 'weight_monitoring',
      'health_entry_id': 'rhythm-1',
      'established_at': '2026-03-01T12:00:00.000Z',
      'policy_version': 'weight_v1',
    });

    expect(model.id, 'est-1');
    expect(model.careFamily, CareFamily.weightMonitoring);
    expect(model.healthEntryId, 'rhythm-1');
    expect(model.policyVersion, 'weight_v1');

    final entity = model.toEntity();
    expect(entity.careFamily, CareFamily.weightMonitoring);
    expect(entity.healthEntryId, 'rhythm-1');
  });

  test('fromJson rejects unknown care_family', () {
    expect(
      () => CareEstablishmentModel.fromJson({
        'id': 'est-1',
        'care_family': 'unknown_family',
        'health_entry_id': 'rhythm-1',
        'established_at': '2026-03-01T12:00:00.000Z',
        'policy_version': 'weight_v1',
      }),
      throwsFormatException,
    );
  });
}
