import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../domain/entities/absence_care_plan.dart';

class AwayPlanPlannerCopy {
  const AwayPlanPlannerCopy._();

  static String formatDate(String iso) {
    final parsed = parseCalendarDate(iso);
    if (parsed == null) return iso;
    return formatCalendarDateDisplay(parsed);
  }

  static String moveLine(AppLocalizations l, CarePlannerSuggestion suggestion) {
    return l.plannerMoveLine(
      formatDate(suggestion.fromDate),
      formatDate(suggestion.toDate),
    );
  }

  static String reasonLine(
    AppLocalizations l,
    CarePlannerSuggestion suggestion,
  ) {
    return switch (suggestion.rationaleCode) {
      'move_after_return' => l.plannerReasonAfterReturn,
      'overdue_do_before_departure' => l.plannerReasonBeforeDeparture,
      _ => l.plannerReasonBeforeDeparture,
    };
  }
}
