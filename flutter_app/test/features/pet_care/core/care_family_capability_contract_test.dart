import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_care/core/care_family_capabilities.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';

/// Contract matrix — must match server/lib/care/capabilities.js (CAPABILITY_MATRIX).
const _serverCapabilityContract = <String, Map<String, dynamic>>{
  'weight_monitoring': {
    'supportsEstablishment': true,
    'supportsMilestones': true,
    'supportsObservations': true,
    'observationKind': 'numeric_weight',
    'entitlementClass': 'core',
  },
  'medication': {
    'supportsEstablishment': false,
    'supportsMilestones': false,
    'supportsObservations': false,
    'observationKind': null,
    'entitlementClass': 'core',
  },
  'vaccination': {
    'supportsEstablishment': false,
    'supportsMilestones': false,
    'supportsObservations': false,
    'observationKind': null,
    'entitlementClass': 'core',
  },
  'parasite_prevention': {
    'supportsEstablishment': false,
    'supportsMilestones': false,
    'supportsObservations': false,
    'observationKind': null,
    'entitlementClass': 'core',
  },
  'wellness_review': {
    'supportsEstablishment': false,
    'supportsMilestones': false,
    'supportsObservations': false,
    'observationKind': null,
    'entitlementClass': 'core',
  },
  'dental': {
    'supportsEstablishment': false,
    'supportsMilestones': false,
    'supportsObservations': false,
    'observationKind': null,
    'entitlementClass': 'core',
  },
  'grooming': {
    'supportsEstablishment': false,
    'supportsMilestones': false,
    'supportsObservations': false,
    'observationKind': null,
    'entitlementClass': 'optional_catalog',
  },
  'nail_care': {
    'supportsEstablishment': false,
    'supportsMilestones': false,
    'supportsObservations': false,
    'observationKind': null,
    'entitlementClass': 'optional_catalog',
  },
  'other': {
    'supportsEstablishment': false,
    'supportsMilestones': false,
    'supportsObservations': false,
    'observationKind': null,
    'entitlementClass': 'core',
  },
};

void main() {
  test('CareFamily wire values cover server CARE_FAMILIES contract', () {
    expect(_serverCapabilityContract.keys.toSet(), {
      for (final family in CareFamily.values) family.wireValue,
    });
  });

  test('Flutter capability matrix matches server contract per family', () {
    for (final entry in _serverCapabilityContract.entries) {
      final family = CareFamilyWire.fromWire(entry.key);
      expect(family, isNotNull, reason: 'missing CareFamily for ${entry.key}');
      final caps = CareFamilyCapabilityPolicy.forFamily(family!);
      expect(caps, isNotNull);

      expect(caps!.supportsEstablishment, entry.value['supportsEstablishment']);
      expect(caps.supportsMilestones, entry.value['supportsMilestones']);
      expect(caps.supportsObservations, entry.value['supportsObservations']);
      expect(caps.observationKind, entry.value['observationKind']);
      expect(caps.entitlementClass.wireValue, entry.value['entitlementClass']);
      expect(caps.supportsCareEvents, isTrue);
      expect(caps.supportsRecurrence, isTrue);
      expect(caps.speciesApplicability, ['dog', 'cat']);
    }
  });

  test('only weight monitoring supports V1 establishment and milestones', () {
    final established = CareFamily.values
        .where(CareFamilyCapabilityPolicy.supportsEstablishment)
        .toList();
    final milestones = CareFamily.values
        .where(CareFamilyCapabilityPolicy.supportsMilestones)
        .toList();
    expect(established, [CareFamily.weightMonitoring]);
    expect(milestones, [CareFamily.weightMonitoring]);
  });
}
