import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';

String entryFrequencyLabel(AppLocalizations l, HealthFrequency frequency) {
  switch (frequency) {
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

String entryPeriodLabel(
  AppLocalizations l,
  HealthFrequency frequency,
  int interval,
) {
  final plural = interval != 1;
  switch (frequency) {
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
      return entryFrequencyLabel(l, frequency);
  }
}

String formatEntryDate(DateTime date) => formatCalendarDateDisplay(date);
