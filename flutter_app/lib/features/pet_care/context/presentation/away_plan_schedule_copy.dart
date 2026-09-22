import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../health_tracking/presentation/widgets/health_entry_form/health_entry_frequency_labels.dart';
import '../domain/entities/care_period_coverage.dart';

class AwayPlanScheduleCopy {
  const AwayPlanScheduleCopy._();

  static String plannedCareRowTitle(PlannedCareItem item) {
    final prefix = item.isConditional ? '~ ' : '';
    return '$prefix${item.name}';
  }

  /// Primary schedule line for a unified planned-care row (D-AWD-004).
  static String plannedCareScheduleLine(
    AppLocalizations l,
    PlannedCareItem item,
  ) {
    return switch (item.kind) {
      PlannedCareKind.recurringCalendar => _recurringCalendarLine(l, item),
      PlannedCareKind.recurringChain => _recurringChainLine(l, item),
      PlannedCareKind.singleOnce => _singleOnceLine(l, item),
      PlannedCareKind.indeterminatePending => indeterminateReasonLine(
        l,
        item.reason,
      ),
    };
  }

  /// Secondary lines below the schedule line (next due date, times of day).
  static List<String> plannedCareDetailLines(
    AppLocalizations l,
    PlannedCareItem item,
  ) {
    final lines = <String>[];

    if (item.kind == PlannedCareKind.recurringCalendar &&
        item.nextDueDate != null &&
        item.nextDueDate!.isNotEmpty &&
        item.timesOfDay.length <= 1) {
      lines.add(
        l.awayPlanningEventNextDueDate(_formatCalendarDate(item.nextDueDate!)),
      );
    }

    for (final time in item.timesOfDay) {
      if (time.isEmpty) continue;
      lines.add(l.awayPlanningEventTimeOfDay(time));
    }

    return lines;
  }

  /// Full PDF/handover line: title — schedule (+ detail lines joined).
  static String plannedCareHandoverLine(
    AppLocalizations l,
    PlannedCareItem item,
  ) {
    final parts = [
      plannedCareScheduleLine(l, item),
      ...plannedCareDetailLines(l, item),
    ];
    return '${plannedCareRowTitle(item)} — ${parts.join(' · ')}';
  }

  static String indeterminateReasonLine(AppLocalizations l, String? reason) {
    return switch (reason) {
      'from_completion_pending' => l.awayPlanningIndeterminatePending,
      'from_completion_chain' => l.awayPlanningIndeterminateChain,
      _ => l.awayPlanningIndeterminateGeneric,
    };
  }

  static String _recurringCalendarLine(
    AppLocalizations l,
    PlannedCareItem item,
  ) {
    final interval = item.frequencyInterval;
    final period = _periodLabel(l, item.frequency, interval);
    final start = _formatCalendarDate(item.firstScheduledDate ?? '');
    final end = _formatCalendarDate(item.lastScheduledDate ?? '');
    return l.awayPlanningEventRepeatsFromUntil(interval, period, start, end);
  }

  static String _recurringChainLine(AppLocalizations l, PlannedCareItem item) {
    final interval = item.frequencyInterval;
    final period = _periodLabel(l, item.frequency, interval);
    return l.awayPlanningEventRepeatsFromCompletion(interval, period);
  }

  static String _singleOnceLine(AppLocalizations l, PlannedCareItem item) {
    return l.awayPlanningEventSingleCareOn(
      _formatCalendarDate(item.scheduledDate ?? ''),
    );
  }

  static String _periodLabel(
    AppLocalizations l,
    String? frequencyWire,
    int interval,
  ) {
    final frequency = _frequencyFromWire(frequencyWire);
    return healthEntryPeriodLabel(l, frequency, interval);
  }

  static HealthFrequency _frequencyFromWire(String? raw) {
    return switch (raw) {
      'daily' => HealthFrequency.daily,
      'weekly' => HealthFrequency.weekly,
      'monthly' => HealthFrequency.monthly,
      'yearly' => HealthFrequency.yearly,
      'custom' => HealthFrequency.custom,
      _ => HealthFrequency.once,
    };
  }

  static String _formatCalendarDate(String iso) {
    final parsed = parseCalendarDate(iso);
    if (parsed == null) return iso;
    return formatCalendarDateDisplay(parsed);
  }
}
