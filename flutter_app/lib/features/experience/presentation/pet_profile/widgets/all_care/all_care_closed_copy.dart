import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_lifecycle_list_status.dart';
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
