import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

String allCareClosedCareLinkLabel(AppLocalizations l, int count) {
  return l.allCareClosedCareLink(count);
}

String allCareClosedCareTitleLabel(AppLocalizations l) {
  return l.allCareClosedCareTitle;
}

String allCareClosedCareEmptyLabel(AppLocalizations l) {
  return l.allCareClosedCareEmpty;
}

String closedCareRowStatusLabel(AppLocalizations l, String? careClosedReason) {
  return formatHealthEntryClosedStatusLabel(l, careClosedReason);
}
