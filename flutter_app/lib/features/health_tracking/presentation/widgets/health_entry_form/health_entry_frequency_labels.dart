import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/health_entry.dart';

String healthEntryFrequencyLabel(AppLocalizations l, HealthFrequency f) {
  switch (f) {
    case HealthFrequency.once:
      return l.doesNotRepeat;
    case HealthFrequency.daily:
      return l.daily;
    case HealthFrequency.weekly:
      return l.weekly;
    case HealthFrequency.monthly:
      return l.monthly;
    case HealthFrequency.yearly:
      return l.yearly;
    case HealthFrequency.custom:
      return l.custom;
  }
}

String healthEntryPeriodLabel(
  AppLocalizations l,
  HealthFrequency f,
  int interval,
) {
  final plural = interval != 1;
  switch (f) {
    case HealthFrequency.daily:
      return plural ? l.periodDays : l.daily;
    case HealthFrequency.weekly:
      return plural ? l.periodWeeks : l.weekly;
    case HealthFrequency.monthly:
      return plural ? l.periodMonths : l.monthly;
    case HealthFrequency.yearly:
      return plural ? l.periodYears : l.yearly;
    case HealthFrequency.once:
    case HealthFrequency.custom:
      return healthEntryFrequencyLabel(l, f);
  }
}

String formatHealthEntryCalendarDate(DateTime dt) {
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
