import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/care_family.dart';

String careFamilyLabel(AppLocalizations l10n, CareFamily family) {
  return switch (family) {
    CareFamily.medication => l10n.careFamilyMedication,
    CareFamily.vaccination => l10n.careFamilyVaccination,
    CareFamily.parasitePrevention => l10n.careFamilyParasitePrevention,
    CareFamily.wellnessReview => l10n.careFamilyWellnessReview,
    CareFamily.dental => l10n.careFamilyDental,
    CareFamily.weightMonitoring => l10n.careFamilyWeightMonitoring,
    CareFamily.grooming => l10n.careFamilyGrooming,
    CareFamily.nailCare => l10n.careFamilyNailCare,
    CareFamily.other => l10n.careFamilyOther,
  };
}
