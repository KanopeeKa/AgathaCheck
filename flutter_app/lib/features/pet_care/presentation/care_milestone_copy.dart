import '../../../../l10n/app_localizations.dart';
import '../progression/domain/entities/care_pending_moment.dart';

String careMilestoneMomentBody(
  AppLocalizations l, {
  required String petName,
  required CarePendingMoment moment,
}) {
  if (moment.includesFirstCare) {
    return l.careProgressionFirstCareCombinedBody(petName);
  }
  return l.careProgressionWeightEstablishedBody(petName);
}
