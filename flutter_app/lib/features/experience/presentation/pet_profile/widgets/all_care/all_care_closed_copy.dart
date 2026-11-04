import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Localized copy for Closed care surfaces (CARE-STATUS-R-021).
///
/// Strings live here so phase PRs can ship ARB-free companions; fold into l10n
/// when a later change can include generated `app_localizations*.dart`.
bool _isFrench(AppLocalizations l) => l.localeName.startsWith('fr');

String allCareClosedCareLinkLabel(AppLocalizations l, int count) {
  if (_isFrench(l)) return 'Soins fermés ($count)';
  return 'Closed care ($count)';
}

String allCareClosedCareTitleLabel(AppLocalizations l) {
  if (_isFrench(l)) return 'Soins fermés';
  return 'Closed care';
}

String allCareClosedCareEmptyLabel(AppLocalizations l) {
  if (_isFrench(l)) return 'Aucun soin fermé pour le moment.';
  return 'No closed care yet.';
}

String closedCareRowStatusLabel(AppLocalizations l, String? careClosedReason) {
  if (careClosedReason == 'stopped_by_user') {
    if (_isFrench(l)) return 'Fermé · Arrêté par vous';
    return 'Closed · Stopped by you';
  }
  if (_isFrench(l)) return 'Fermé · Terminé';
  return 'Closed · Ended';
}
