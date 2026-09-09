import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';

/// Entitlement class hooks for future paywall runtime (documentation only in V1).
enum CareEntitlementClass {
  core,
  optionalCatalog,
  deviceBacked,
  partnerImport,
}

extension CareEntitlementClassWire on CareEntitlementClass {
  String get wireValue {
    switch (this) {
      case CareEntitlementClass.core:
        return 'core';
      case CareEntitlementClass.optionalCatalog:
        return 'optional_catalog';
      case CareEntitlementClass.deviceBacked:
        return 'device_backed';
      case CareEntitlementClass.partnerImport:
        return 'partner_import';
    }
  }
}

/// Capability flags for a care family — mirrors server CareFamilyCapabilityPolicy.
class CareFamilyCapabilities {
  const CareFamilyCapabilities({
    required this.supportsCareEvents,
    required this.supportsRecurrence,
    required this.supportsObservations,
    this.observationKind,
    required this.supportsTrendView,
    required this.supportsEstablishment,
    required this.supportsMilestones,
    required this.speciesApplicability,
    required this.entitlementClass,
  });

  final bool supportsCareEvents;
  final bool supportsRecurrence;
  final bool supportsObservations;
  final String? observationKind;
  final bool supportsTrendView;
  final bool supportsEstablishment;
  final bool supportsMilestones;
  final List<String> speciesApplicability;
  final CareEntitlementClass entitlementClass;
}

/// Code-defined capability matrix — keep in sync with server/lib/care/capabilities.js.
class CareFamilyCapabilityPolicy {
  static const _matrix = <CareFamily, CareFamilyCapabilities>{
    CareFamily.weightMonitoring: CareFamilyCapabilities(
      supportsCareEvents: true,
      supportsRecurrence: true,
      supportsObservations: true,
      observationKind: 'numeric_weight',
      supportsTrendView: true,
      supportsEstablishment: true,
      supportsMilestones: true,
      speciesApplicability: ['dog', 'cat'],
      entitlementClass: CareEntitlementClass.core,
    ),
    CareFamily.medication: CareFamilyCapabilities(
      supportsCareEvents: true,
      supportsRecurrence: true,
      supportsObservations: false,
      supportsTrendView: false,
      supportsEstablishment: false,
      supportsMilestones: false,
      speciesApplicability: ['dog', 'cat'],
      entitlementClass: CareEntitlementClass.core,
    ),
    CareFamily.vaccination: CareFamilyCapabilities(
      supportsCareEvents: true,
      supportsRecurrence: true,
      supportsObservations: false,
      supportsTrendView: false,
      supportsEstablishment: false,
      supportsMilestones: false,
      speciesApplicability: ['dog', 'cat'],
      entitlementClass: CareEntitlementClass.core,
    ),
    CareFamily.parasitePrevention: CareFamilyCapabilities(
      supportsCareEvents: true,
      supportsRecurrence: true,
      supportsObservations: false,
      supportsTrendView: false,
      supportsEstablishment: false,
      supportsMilestones: false,
      speciesApplicability: ['dog', 'cat'],
      entitlementClass: CareEntitlementClass.core,
    ),
    CareFamily.wellnessReview: CareFamilyCapabilities(
      supportsCareEvents: true,
      supportsRecurrence: true,
      supportsObservations: false,
      supportsTrendView: false,
      supportsEstablishment: false,
      supportsMilestones: false,
      speciesApplicability: ['dog', 'cat'],
      entitlementClass: CareEntitlementClass.core,
    ),
    CareFamily.dental: CareFamilyCapabilities(
      supportsCareEvents: true,
      supportsRecurrence: true,
      supportsObservations: false,
      supportsTrendView: false,
      supportsEstablishment: false,
      supportsMilestones: false,
      speciesApplicability: ['dog', 'cat'],
      entitlementClass: CareEntitlementClass.core,
    ),
    CareFamily.grooming: CareFamilyCapabilities(
      supportsCareEvents: true,
      supportsRecurrence: true,
      supportsObservations: false,
      supportsTrendView: false,
      supportsEstablishment: false,
      supportsMilestones: false,
      speciesApplicability: ['dog', 'cat'],
      entitlementClass: CareEntitlementClass.optionalCatalog,
    ),
    CareFamily.nailCare: CareFamilyCapabilities(
      supportsCareEvents: true,
      supportsRecurrence: true,
      supportsObservations: false,
      supportsTrendView: false,
      supportsEstablishment: false,
      supportsMilestones: false,
      speciesApplicability: ['dog', 'cat'],
      entitlementClass: CareEntitlementClass.optionalCatalog,
    ),
    CareFamily.other: CareFamilyCapabilities(
      supportsCareEvents: true,
      supportsRecurrence: true,
      supportsObservations: false,
      supportsTrendView: false,
      supportsEstablishment: false,
      supportsMilestones: false,
      speciesApplicability: ['dog', 'cat'],
      entitlementClass: CareEntitlementClass.core,
    ),
  };

  static CareFamilyCapabilities? forFamily(CareFamily family) => _matrix[family];

  static Iterable<CareFamily> get allFamilies => _matrix.keys;

  static bool supportsEstablishment(CareFamily family) =>
      forFamily(family)?.supportsEstablishment ?? false;

  static bool supportsMilestones(CareFamily family) =>
      forFamily(family)?.supportsMilestones ?? false;

  static bool speciesSupportsFamily(CareFamily family, String species) {
    final caps = forFamily(family);
    if (caps == null) return false;
    return caps.speciesApplicability.contains(species.toLowerCase());
  }
}
