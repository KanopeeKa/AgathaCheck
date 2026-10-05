import '../../../../l10n/app_localizations.dart';

String householdTierLabel(AppLocalizations l, String tier, {bool organiser = false}) {
  if (organiser) return l.householdOrganiserLabel;
  if (tier == 'can_log_care') return l.householdCanLogCareLabel;
  return l.householdFullAccessLabel;
}
