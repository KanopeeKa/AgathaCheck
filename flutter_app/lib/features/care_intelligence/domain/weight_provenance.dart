/// Weight provenance enums (D0 contract). Distinct from [CareSource] on health rhythms.
library;

enum MeasurementSource { guardian, clinic, device, imported }

enum ReferenceAuthority { vetTarget, guardianReference, historicalBaseline }

enum ManagementContext { none, vetManaged, carePlan, treatmentRelated }

extension MeasurementSourceWire on MeasurementSource {
  String get wireValue => switch (this) {
    MeasurementSource.guardian => 'guardian',
    MeasurementSource.clinic => 'clinic',
    MeasurementSource.device => 'device',
    MeasurementSource.imported => 'imported',
  };

  static MeasurementSource? fromWire(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'guardian':
        return MeasurementSource.guardian;
      case 'clinic':
        return MeasurementSource.clinic;
      case 'device':
        return MeasurementSource.device;
      case 'imported':
        return MeasurementSource.imported;
      default:
        return null;
    }
  }
}

extension ReferenceAuthorityWire on ReferenceAuthority {
  String get wireValue => switch (this) {
    ReferenceAuthority.vetTarget => 'vet_target',
    ReferenceAuthority.guardianReference => 'guardian_reference',
    ReferenceAuthority.historicalBaseline => 'historical_baseline',
  };

  static ReferenceAuthority? fromWire(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'vet_target':
        return ReferenceAuthority.vetTarget;
      case 'guardian_reference':
        return ReferenceAuthority.guardianReference;
      case 'historical_baseline':
        return ReferenceAuthority.historicalBaseline;
      default:
        return null;
    }
  }
}

extension ManagementContextWire on ManagementContext {
  String get wireValue => switch (this) {
    ManagementContext.none => 'none',
    ManagementContext.vetManaged => 'vet_managed',
    ManagementContext.carePlan => 'care_plan',
    ManagementContext.treatmentRelated => 'treatment_related',
  };

  static ManagementContext fromWire(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'vet_managed':
        return ManagementContext.vetManaged;
      case 'care_plan':
        return ManagementContext.carePlan;
      case 'treatment_related':
        return ManagementContext.treatmentRelated;
      case 'none':
      case null:
      case '':
        return ManagementContext.none;
      default:
        return ManagementContext.none;
    }
  }
}

/// Pet-level weight context for review-relevance (not inferred from measurements).
class PetWeightContext {
  const PetWeightContext({
    this.referenceValue,
    this.referenceAuthority,
    this.managementContext = ManagementContext.none,
  });

  final double? referenceValue;
  final ReferenceAuthority? referenceAuthority;
  final ManagementContext managementContext;
}
