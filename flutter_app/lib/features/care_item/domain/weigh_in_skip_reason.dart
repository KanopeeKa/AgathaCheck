import '../../../l10n/app_localizations.dart';

/// Skip reason payload on occurrence detail (`skip_reason` from the API).
class OccurrenceSkipReason {
  const OccurrenceSkipReason({this.code, this.note});

  final String? code;
  final String? note;
}

/// Localized label for a weigh-in skip [code] (D-WM-015).
String? weighInSkipReasonLabel(AppLocalizations l, String? code) {
  if (code == null || code.isEmpty) return null;
  switch (code) {
    case 'could_not_weigh':
      return l.careSkipReasonCouldNotWeigh;
    case 'pet_unsettled':
      return l.careSkipReasonPetUnsettled;
    case 'vet_will_weigh':
      return l.careSkipReasonVetWillWeigh;
    case 'other':
      return l.careSkipReasonOther;
    default:
      return code;
  }
}
