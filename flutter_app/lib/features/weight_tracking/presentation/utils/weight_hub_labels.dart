import 'package:intl/intl.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../core/weight/weight_unit.dart';
import '../../../../l10n/app_localizations.dart';

String weightAuthorityLabel(AppLocalizations l, String authority) {
  switch (authority) {
    case 'vet_target':
      return l.weightAuthorityVet;
    case 'guardian_reference':
      return l.weightAuthorityGuardian;
    case 'historical_baseline':
      return l.weightAuthorityBaseline;
    default:
      return l.weightAuthorityGuardian;
  }
}

String weightSourceChipLabel(AppLocalizations l, String measurementSource) {
  switch (measurementSource) {
    case 'clinic':
      return l.weightSourceClinic;
    case 'device':
      return l.weightSourceDevice;
    case 'imported':
      return l.weightSourceImported;
    default:
      return l.weightLegendOther;
  }
}

String careOccurrenceStatusLabel(AppLocalizations l, String apiStatus) {
  switch (apiStatus) {
    case 'overdue':
      return l.overdue;
    case 'due':
      return l.careStatusDue;
    case 'coming_up':
      return l.careStatusComingUp;
    case 'not_recorded':
      return l.careStatusNotRecorded;
    default:
      return l.careStatusComingUp;
  }
}

String formatWeightChange(
  AppLocalizations l,
  double deltaKg,
  WeightUnit unit,
  DateTime sinceDate,
) {
  final sign = deltaKg >= 0 ? '+' : '';
  final display = formatWeight(deltaKg.abs(), unit);
  final dateLabel = DateFormat.yMMMd().format(calendarDateOnly(sinceDate));
  return l.weightSinceChange('$sign$display', dateLabel);
}
