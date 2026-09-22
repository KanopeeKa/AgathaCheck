import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_family_definition.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_importance.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_setting.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_taxonomy.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';

void main() {
  group('CareTaxonomy', () {
    test('covers all care families', () {
      expect(CareTaxonomy.families.keys, containsAll(CareFamily.values));
    });

    test('matches shared/care_taxonomy.json defaults', () {
      final repoRoot = Directory.current.path.contains('flutter_app')
          ? Directory.current.parent
          : Directory.current;
      final jsonPath = '${repoRoot.path}/shared/care_taxonomy.json';
      final raw = File(jsonPath).readAsStringSync();
      final taxonomy = jsonDecode(raw) as Map<String, dynamic>;
      final families = taxonomy['families'] as Map<String, dynamic>;

      for (final family in CareFamily.values) {
        final wire = family.wireValue;
        final jsonDef = families[wire] as Map<String, dynamic>;
        final dartDef = CareTaxonomy.families[family]!;

        expect(
          dartDef.defaultSetting.wireValue,
          jsonDef['default_setting'],
          reason: wire,
        );
        expect(
          dartDef.defaultImportance.wireValue,
          jsonDef['default_importance'],
          reason: wire,
        );
        expect(
          dartDef.filterGroup.wireValue,
          jsonDef['filter_group'],
          reason: wire,
        );

        final legacy = jsonDef['derived_legacy_type'] as Map<String, dynamic>;
        for (final setting in CareSetting.values) {
          expect(
            dartDef.derivedLegacyTypeBySetting[setting],
            legacy[setting.wireValue],
            reason: '$wire/${setting.wireValue}',
          );
        }
      }
    });

    test('derives legacy type for vaccination at vet', () {
      expect(
        CareTaxonomy.deriveLegacyHealthEntryType(
          family: CareFamily.vaccination,
          setting: CareSetting.vet,
        ),
        'preventive',
      );
    });
  });
}
