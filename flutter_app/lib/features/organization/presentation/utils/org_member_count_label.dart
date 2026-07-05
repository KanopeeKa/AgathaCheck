import '../../../../l10n/app_localizations.dart';

String orgMemberCountLabel(AppLocalizations l, int registered, int external) {
  if (external > 0) {
    return l.orgMemberCountSummary(registered, external);
  }
  return l.orgMemberCountRegisteredOnly(registered);
}
