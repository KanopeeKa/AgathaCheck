/// Provenance for established care configuration.
enum CareSource {
  guardianDefined,
  vetInstruction,
  treatmentSchedule,
  carePlan,
  agathaAccepted,
  agathaAdjusted,
  systemDefault,
}

extension CareSourceWire on CareSource {
  String get wireValue {
    switch (this) {
      case CareSource.guardianDefined:
        return 'guardian_defined';
      case CareSource.vetInstruction:
        return 'vet_instruction';
      case CareSource.treatmentSchedule:
        return 'treatment_schedule';
      case CareSource.carePlan:
        return 'care_plan';
      case CareSource.agathaAccepted:
        return 'agatha_accepted';
      case CareSource.agathaAdjusted:
        return 'agatha_adjusted';
      case CareSource.systemDefault:
        return 'system_default';
    }
  }

  static CareSource? fromWire(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return switch (raw) {
      'guardian_defined' => CareSource.guardianDefined,
      'vet_instruction' => CareSource.vetInstruction,
      'treatment_schedule' => CareSource.treatmentSchedule,
      'care_plan' => CareSource.carePlan,
      'agatha_accepted' => CareSource.agathaAccepted,
      'agatha_adjusted' => CareSource.agathaAdjusted,
      'system_default' => CareSource.systemDefault,
      _ => null,
    };
  }
}
