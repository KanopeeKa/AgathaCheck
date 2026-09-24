import 'package:flutter/material.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../health_tracking/presentation/widgets/care_event_status_line.dart';
import '../../../health_tracking/presentation/widgets/health_entry_form/health_entry_frequency_labels.dart';
import '../../../health_tracking/presentation/widgets/health_entry_status.dart'
    as entry_status;
import '../domain/entities/care_period_coverage.dart';

class AwayPlanScheduleCopy {
  const AwayPlanScheduleCopy._();

  static String plannedCareRowTitle(PlannedCareItem item) => item.name;

  /// Primary schedule line for a unified planned-care row (D-AWD-004).
  static String plannedCareScheduleLine(
    AppLocalizations l,
    PlannedCareItem item,
  ) {
    if (item.isPaused) {
      return pausedLine(l);
    }
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

  static String pausedLine(AppLocalizations l) => l.awayPlanningPaused;

  /// Open-occurrence date line (R-A3). Null when no open occurrence on the row.
  static CareEventStatusLine? openOccurrenceStatusLine(
    AppLocalizations l,
    PlannedCareItem item,
    ColorScheme colorScheme,
  ) {
    final open = item.openOccurrence;
    if (open == null) return null;

    final instant = _formatOpenInstant(l, open);
    return switch (open.openStatus) {
      'overdue' => CareEventStatusLine(
        text: '$instant · ${l.urgencyOverdue}',
        statusSuffix: l.urgencyOverdue,
        suffixTreatment: entry_status.overdueStatusTreatment(colorScheme),
      ),
      'due_before_absence' => CareEventStatusLine(
        text: l.awayPlanningOpenDueBeforeLeave(instant),
      ),
      'in_window' => null,
      _ => CareEventStatusLine(text: instant),
    };
  }

  /// In-window summary line (R-A4, R-A5).
  static String? inWindowLine(AppLocalizations l, PlannedCareItem item) {
    final window = item.inWindow;
    if (window == null) return null;

    if (window.count > 1) {
      return l.awayPlanningInWindowRange(
        window.count,
        _formatCalendarDate(window.firstDate),
        _formatCalendarDate(window.lastDate),
      );
    }

    final date = _formatCalendarDate(window.firstDate);
    return switch (window.dateBasis) {
      'planned' => l.awayPlanningPlannedOn(date),
      'estimated' => l.awayPlanningEstimatedOn(date),
      _ => date,
    };
  }

  /// Secondary lines below the schedule line (times of day; legacy next-due when no ACP contract).
  static List<String> plannedCareDetailLines(
    AppLocalizations l,
    PlannedCareItem item,
  ) {
    if (item.isPaused || item.usesAcpRowContract) {
      return _timeOfDayLines(l, item);
    }

    final lines = <String>[];

    if (item.kind == PlannedCareKind.recurringCalendar &&
        item.nextDueDate != null &&
        item.nextDueDate!.isNotEmpty &&
        item.timesOfDay.length <= 1) {
      lines.add(
        l.awayPlanningEventNextDueDate(_formatCalendarDate(item.nextDueDate!)),
      );
    }

    lines.addAll(_timeOfDayLines(l, item));
    return lines;
  }

  static List<String> _timeOfDayLines(
    AppLocalizations l,
    PlannedCareItem item,
  ) {
    final lines = <String>[];
    for (final time in item.timesOfDay) {
      if (time.isEmpty) continue;
      lines.add(l.awayPlanningEventTimeOfDay(time));
    }
    return lines;
  }

  /// Full PDF/handover line: title — schedule (+ contract + detail lines joined).
  static String plannedCareHandoverLine(
    AppLocalizations l,
    PlannedCareItem item,
  ) {
    final parts = <String>[plannedCareScheduleLine(l, item)];

    final open = item.openOccurrence;
    if (open != null) {
      final instant = _formatOpenInstant(l, open);
      parts.add(switch (open.openStatus) {
        'overdue' => '$instant · ${l.urgencyOverdue}',
        'due_before_absence' => l.awayPlanningOpenDueBeforeLeave(instant),
        _ => instant,
      });
    }

    final windowLine = inWindowLine(l, item);
    if (windowLine != null) {
      parts.add(windowLine);
    }

    parts.addAll(plannedCareDetailLines(l, item));

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

  static String _formatOpenInstant(
    AppLocalizations l,
    PlannedCareOpenOccurrence open,
  ) {
    final date = _formatCalendarDate(open.scheduledDate);
    final time = open.scheduledTime;
    if (time == null || time.isEmpty) return date;
    return l.occurrenceDateAtTime(date, time);
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
