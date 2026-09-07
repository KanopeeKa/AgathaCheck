import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/care_source.dart';

/// Localized provenance label for established care configuration.
String? careSourceLabel(AppLocalizations l, CareSource? source) {
  if (source == null) return null;
  return switch (source) {
    CareSource.guardianDefined => l.careSourceGuardianDefined,
    CareSource.vetInstruction => l.careSourceVetInstruction,
    CareSource.treatmentSchedule => l.careSourceTreatmentSchedule,
    CareSource.carePlan => l.careSourceCarePlan,
    CareSource.agathaAccepted => l.careSourceAgathaAccepted,
    CareSource.agathaAdjusted => l.careSourceAgathaAdjusted,
    CareSource.systemDefault => l.careSourceSystemDefault,
  };
}
