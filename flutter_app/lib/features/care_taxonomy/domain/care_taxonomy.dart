import '../../pet_profile/domain/entities/care_family.dart';
import 'care_family_definition.dart';
import 'care_importance.dart';
import 'care_setting.dart';

/// Canonical care taxonomy — mirrors [shared/care_taxonomy.json] and server registry.
class CareTaxonomy {
  CareTaxonomy._();

  static const nullFamilyDefaultSetting = CareSetting.other;
  static const nullFamilyDefaultImportance = CareImportance.optional;

  static final Map<CareFamily, CareFamilyDefinition> families = {
    CareFamily.medication: CareFamilyDefinition(
      family: CareFamily.medication,
      defaultSetting: CareSetting.home,
      defaultImportance: CareImportance.essential,
      filterGroup: CareFilterGroup.prevention,
      derivedLegacyTypeBySetting: {
        CareSetting.home: 'medication',
        CareSetting.vet: 'medication',
        CareSetting.other: 'medication',
      },
    ),
    CareFamily.vaccination: CareFamilyDefinition(
      family: CareFamily.vaccination,
      defaultSetting: CareSetting.vet,
      defaultImportance: CareImportance.essential,
      filterGroup: CareFilterGroup.prevention,
      derivedLegacyTypeBySetting: {
        CareSetting.home: 'preventive',
        CareSetting.vet: 'preventive',
        CareSetting.other: 'preventive',
      },
    ),
    CareFamily.parasitePrevention: CareFamilyDefinition(
      family: CareFamily.parasitePrevention,
      defaultSetting: CareSetting.home,
      defaultImportance: CareImportance.essential,
      filterGroup: CareFilterGroup.prevention,
      derivedLegacyTypeBySetting: {
        CareSetting.home: 'preventive',
        CareSetting.vet: 'preventive',
        CareSetting.other: 'preventive',
      },
    ),
    CareFamily.wellnessReview: CareFamilyDefinition(
      family: CareFamily.wellnessReview,
      defaultSetting: CareSetting.vet,
      defaultImportance: CareImportance.recommended,
      filterGroup: CareFilterGroup.clinical,
      derivedLegacyTypeBySetting: {
        CareSetting.home: 'other',
        CareSetting.vet: 'vet_visit',
        CareSetting.other: 'other',
      },
    ),
    CareFamily.dental: CareFamilyDefinition(
      family: CareFamily.dental,
      defaultSetting: CareSetting.vet,
      defaultImportance: CareImportance.recommended,
      filterGroup: CareFilterGroup.clinical,
      derivedLegacyTypeBySetting: {
        CareSetting.home: 'other',
        CareSetting.vet: 'vet_visit',
        CareSetting.other: 'other',
      },
    ),
    CareFamily.weightMonitoring: CareFamilyDefinition(
      family: CareFamily.weightMonitoring,
      defaultSetting: CareSetting.home,
      defaultImportance: CareImportance.recommended,
      filterGroup: CareFilterGroup.clinical,
      derivedLegacyTypeBySetting: {
        CareSetting.home: 'other',
        CareSetting.vet: 'vet_visit',
        CareSetting.other: 'other',
      },
    ),
    CareFamily.grooming: CareFamilyDefinition(
      family: CareFamily.grooming,
      defaultSetting: CareSetting.other,
      defaultImportance: CareImportance.optional,
      filterGroup: CareFilterGroup.lifestyle,
      derivedLegacyTypeBySetting: {
        CareSetting.home: 'other',
        CareSetting.vet: 'other',
        CareSetting.other: 'other',
      },
    ),
    CareFamily.nailCare: CareFamilyDefinition(
      family: CareFamily.nailCare,
      defaultSetting: CareSetting.other,
      defaultImportance: CareImportance.optional,
      filterGroup: CareFilterGroup.lifestyle,
      derivedLegacyTypeBySetting: {
        CareSetting.home: 'other',
        CareSetting.vet: 'other',
        CareSetting.other: 'other',
      },
    ),
    CareFamily.other: CareFamilyDefinition(
      family: CareFamily.other,
      defaultSetting: CareSetting.other,
      defaultImportance: CareImportance.optional,
      filterGroup: CareFilterGroup.lifestyle,
      derivedLegacyTypeBySetting: {
        CareSetting.home: 'other',
        CareSetting.vet: 'other',
        CareSetting.other: 'other',
      },
    ),
  };

  static CareFamilyDefinition? definitionFor(CareFamily? family) {
    if (family == null) return null;
    return families[family];
  }

  static CareSetting defaultSettingFor(CareFamily? family) {
    return definitionFor(family)?.defaultSetting ?? nullFamilyDefaultSetting;
  }

  static CareImportance defaultImportanceFor(CareFamily? family) {
    return definitionFor(family)?.defaultImportance ??
        nullFamilyDefaultImportance;
  }

  static String deriveLegacyHealthEntryType({
    required CareFamily? family,
    required CareSetting setting,
  }) {
    if (family == null) return 'other';
    final definition = families[family];
    if (definition == null) return 'other';
    return definition.derivedLegacyTypeBySetting[setting] ?? 'other';
  }
}
