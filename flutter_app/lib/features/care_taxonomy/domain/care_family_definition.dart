import '../../pet_profile/domain/entities/care_family.dart';
import 'care_importance.dart';
import 'care_setting.dart';

/// Filter chip grouping for manage-events / dashboard surfaces.
enum CareFilterGroup { prevention, clinical, lifestyle }

extension CareFilterGroupWire on CareFilterGroup {
  String get wireValue {
    switch (this) {
      case CareFilterGroup.prevention:
        return 'prevention';
      case CareFilterGroup.clinical:
        return 'clinical';
      case CareFilterGroup.lifestyle:
        return 'lifestyle';
    }
  }

  static CareFilterGroup? fromWire(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return switch (raw) {
      'prevention' => CareFilterGroup.prevention,
      'clinical' => CareFilterGroup.clinical,
      'lifestyle' => CareFilterGroup.lifestyle,
      _ => null,
    };
  }
}

class CareFamilyDefinition {
  const CareFamilyDefinition({
    required this.family,
    required this.defaultSetting,
    required this.defaultImportance,
    required this.filterGroup,
    required this.derivedLegacyTypeBySetting,
  });

  final CareFamily family;
  final CareSetting defaultSetting;
  final CareImportance defaultImportance;
  final CareFilterGroup filterGroup;
  final Map<CareSetting, String> derivedLegacyTypeBySetting;
}
