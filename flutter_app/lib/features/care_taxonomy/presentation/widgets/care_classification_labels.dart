import '../../../../l10n/app_localizations.dart';
import '../../domain/care_importance.dart';
import '../../domain/care_setting.dart';

String careSettingLabel(AppLocalizations l10n, CareSetting setting) {
  return switch (setting) {
    CareSetting.home => l10n.careSettingHome,
    CareSetting.vet => l10n.careSettingVet,
    CareSetting.other => l10n.careSettingOther,
  };
}

String careImportanceLabel(AppLocalizations l10n, CareImportance importance) {
  return switch (importance) {
    CareImportance.essential => l10n.careImportanceEssential,
    CareImportance.recommended => l10n.careImportanceRecommended,
    CareImportance.optional => l10n.careImportanceOptional,
  };
}
