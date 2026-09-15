import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../domain/entities/care_period_coverage.dart';

class AwayPlanScheduleCopy {
  const AwayPlanScheduleCopy._();

  static String routineRowTitle(CarePeriodRoutineItem item) {
    final prefix = item.isConditional ? '~ ' : '';
    return '$prefix${item.name}';
  }

  static String routineRowSubtitle(
    AppLocalizations l,
    CarePeriodRoutineItem item,
  ) {
    final timeLabel = item.scheduledTime == null || item.scheduledTime!.isEmpty
        ? l.awayPlanningRoutineAllDay
        : item.scheduledTime!;
    return l.awayPlanningRoutineRowSubtitle(
      timeLabel,
      item.occurrenceCount,
      _formatDateRange(item.firstScheduledDate, item.lastScheduledDate),
    );
  }

  static String datedRowStatus(AppLocalizations l, CarePeriodProjectionItem item) {
    final parsed = parseCalendarDate(item.scheduledDate);
    final dateLabel = parsed == null
        ? item.scheduledDate
        : formatCalendarDateDisplay(parsed);
    return switch (item.status) {
      'completed' => l.careContextPreviewItemCompleted(dateLabel),
      'skipped' => l.careContextPreviewItemSkipped(dateLabel),
      _ => l.careContextPreviewItemPending(dateLabel),
    };
  }

  static String indeterminateRowSubtitle(
    AppLocalizations l,
    CarePeriodUncertainty uncertainty,
  ) {
    return switch (uncertainty.reason) {
      'from_completion_pending' => l.awayPlanningIndeterminatePending,
      'from_completion_chain' => l.awayPlanningIndeterminateChain,
      _ => l.awayPlanningIndeterminateGeneric,
    };
  }

  static String _formatDateRange(String startIso, String endIso) {
    final start = parseCalendarDate(startIso);
    final end = parseCalendarDate(endIso);
    if (start == null || end == null) return '$startIso – $endIso';
    if (startIso == endIso) return formatCalendarDateDisplay(start);
    return '${formatCalendarDateDisplay(start)} – ${formatCalendarDateDisplay(end)}';
  }
}
