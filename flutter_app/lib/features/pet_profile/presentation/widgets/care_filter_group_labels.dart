import '../../../../l10n/app_localizations.dart';
import '../../../care_taxonomy/care_taxonomy.dart';

String careFilterGroupLabel(AppLocalizations l10n, CareFilterGroup group) {
  return switch (group) {
    CareFilterGroup.prevention => l10n.careFilterGroupPrevention,
    CareFilterGroup.clinical => l10n.careFilterGroupClinical,
    CareFilterGroup.lifestyle => l10n.careFilterGroupLifestyle,
  };
}
