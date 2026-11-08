import '../../../../l10n/app_localizations.dart';
import '../../../care_intelligence/care_intelligence.dart';

/// User-facing labels for pet weight-context fields on the weight hub.
class WeightContextLabels {
  const WeightContextLabels._();

  static String referenceWeightDisplay(
    AppLocalizations l, {
    required double? valueKg,
  }) {
    if (valueKg == null) return l.notSet;
    return '${valueKg.toStringAsFixed(1)} kg';
  }

  static String referenceAuthorityDisplay(AppLocalizations l, String? wire) {
    final authority = ReferenceAuthorityWire.fromWire(wire);
    if (authority == null) return l.notSet;
    return switch (authority) {
      ReferenceAuthority.vetTarget => l.weightReferenceAuthorityVetTarget,
      ReferenceAuthority.guardianReference =>
        l.weightReferenceAuthorityGuardianReference,
      ReferenceAuthority.historicalBaseline =>
        l.weightReferenceAuthorityHistoricalBaseline,
    };
  }

  static String managementContextDisplay(AppLocalizations l, String wire) {
    final ctx = ManagementContextWire.fromWire(wire);
    return switch (ctx) {
      ManagementContext.none => l.weightManagementContextNone,
      ManagementContext.vetManaged => l.weightManagementContextVetManaged,
      ManagementContext.carePlan => l.weightManagementContextCarePlan,
      ManagementContext.treatmentRelated =>
        l.weightManagementContextTreatmentRelated,
    };
  }
}
