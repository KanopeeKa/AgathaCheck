import '../../../../../l10n/app_localizations.dart';
import '../../../../care_taxonomy/care_taxonomy.dart';

String healthEntryCareSettingLabel(AppLocalizations l10n, CareSetting setting) {
  return switch (setting) {
    CareSetting.home => l10n.careSettingHome,
    CareSetting.vet => l10n.careSettingVet,
    CareSetting.other => l10n.careSettingOther,
  };
}

String healthEntryCareImportanceLabel(
  AppLocalizations l10n,
  CareImportance importance,
) {
  return switch (importance) {
    CareImportance.essential => l10n.careImportanceEssential,
    CareImportance.recommended => l10n.careImportanceRecommended,
    CareImportance.optional => l10n.careImportanceOptional,
  };
}
