import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/care_period_coverage.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/away_plan_schedule_copy.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

PlannedCareItem _item({
  required PlannedCareKind kind,
  String healthEntryId = 'e1',
  String name = 'Daily pill',
  String? type = 'medication',
  String? careFamily = 'medication',
  String? frequency = 'daily',
  int frequencyInterval = 1,
  List<String> timesOfDay = const [],
  String? nextDueDate,
  String? certainty,
  String? reason,
  String? scheduledDate,
  String? firstScheduledDate,
  String? lastScheduledDate,
  PlannedCareOpenOccurrence? openOccurrence,
  PlannedCareInWindow? inWindow,
  bool isPaused = false,
}) {
  return PlannedCareItem(
    kind: kind,
    healthEntryId: healthEntryId,
    name: name,
    type: type,
    careFamily: careFamily,
    frequency: frequency,
    frequencyInterval: frequencyInterval,
    timesOfDay: timesOfDay,
    nextDueDate: nextDueDate,
    certainty: certainty,
    reason: reason,
    scheduledDate: scheduledDate,
    firstScheduledDate: firstScheduledDate,
    lastScheduledDate: lastScheduledDate,
    openOccurrence: openOccurrence,
    inWindow: inWindow,
    isPaused: isPaused,
  );
}

void main() {
  late AppLocalizations l;
  late ColorScheme colorScheme;

  String displayDate(String iso) =>
      formatCalendarDateDisplay(parseCalendarDate(iso)!);

  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('en'));
    colorScheme = ThemeData.light().colorScheme;
  });

  group('plannedCareRowTitle', () {
    test('does not prefix conditional rows with tilde', () {
      expect(
        AwayPlanScheduleCopy.plannedCareRowTitle(
          _item(
            kind: PlannedCareKind.recurringCalendar,
            certainty: 'conditional_on_future_completion',
          ),
        ),
        'Daily pill',
      );
    });
  });

  group('openOccurrenceStatusLine', () {
    test('overdue includes urgencyOverdue suffix', () {
      final line = AwayPlanScheduleCopy.openOccurrenceStatusLine(
        l,
        _item(
          kind: PlannedCareKind.recurringChain,
          openOccurrence: const PlannedCareOpenOccurrence(
            scheduledDate: '2026-09-01',
            openStatus: 'overdue',
          ),
        ),
        colorScheme,
      );
      expect(line!.text, '${displayDate('2026-09-01')} · ${l.urgencyOverdue}');
      expect(line.statusSuffix, l.urgencyOverdue);
      expect(line.suffixTreatment, isNotNull);
    });

    test('due_before_absence uses dedicated copy', () {
      final line = AwayPlanScheduleCopy.openOccurrenceStatusLine(
        l,
        _item(
          kind: PlannedCareKind.recurringChain,
          openOccurrence: const PlannedCareOpenOccurrence(
            scheduledDate: '2026-09-20',
            openStatus: 'due_before_absence',
          ),
        ),
        colorScheme,
      );
      expect(
        line!.text,
        l.awayPlanningOpenDueBeforeLeave(displayDate('2026-09-20')),
      );
    });
  });

  group('inWindowLine', () {
    test('single planned date', () {
      final text = AwayPlanScheduleCopy.inWindowLine(
        l,
        _item(
          kind: PlannedCareKind.recurringCalendar,
          inWindow: const PlannedCareInWindow(
            firstDate: '2026-10-03',
            lastDate: '2026-10-03',
            count: 1,
            dateBasis: 'planned',
          ),
        ),
      );
      expect(text, l.awayPlanningPlannedOn(displayDate('2026-10-03')));
    });

    test('single estimated date', () {
      final text = AwayPlanScheduleCopy.inWindowLine(
        l,
        _item(
          kind: PlannedCareKind.recurringChain,
          inWindow: const PlannedCareInWindow(
            firstDate: '2026-10-04',
            lastDate: '2026-10-04',
            count: 1,
            dateBasis: 'estimated',
          ),
        ),
      );
      expect(text, l.awayPlanningEstimatedOn(displayDate('2026-10-04')));
    });

    test('multiple dates use range copy', () {
      final text = AwayPlanScheduleCopy.inWindowLine(
        l,
        _item(
          kind: PlannedCareKind.recurringCalendar,
          inWindow: const PlannedCareInWindow(
            firstDate: '2026-10-02',
            lastDate: '2026-10-04',
            count: 3,
            dateBasis: 'scheduled',
          ),
        ),
      );
      expect(
        text,
        l.awayPlanningInWindowRange(
          3,
          displayDate('2026-10-02'),
          displayDate('2026-10-04'),
        ),
      );
    });
  });

  group('plannedCareScheduleLine matrix', () {
    test('paused rows show paused copy only', () {
      expect(
        AwayPlanScheduleCopy.plannedCareScheduleLine(
          l,
          _item(kind: PlannedCareKind.recurringChain, isPaused: true),
        ),
        l.awayPlanningPaused,
      );
    });

    test('recurring_calendar uses repeats-from-until copy', () {
      final text = AwayPlanScheduleCopy.plannedCareScheduleLine(
        l,
        _item(
          kind: PlannedCareKind.recurringCalendar,
          firstScheduledDate: '2026-10-01',
          lastScheduledDate: '2026-10-04',
        ),
      );
      expect(
        text,
        l.awayPlanningEventRepeatsFromUntil(
          1,
          l.daily,
          displayDate('2026-10-01'),
          displayDate('2026-10-04'),
        ),
      );
    });

    test('recurring_chain uses repeats-from-completion copy', () {
      final text = AwayPlanScheduleCopy.plannedCareScheduleLine(
        l,
        _item(kind: PlannedCareKind.recurringChain, frequency: 'weekly'),
      );
      expect(text, l.awayPlanningEventRepeatsFromCompletion(1, l.weekly));
    });

    test('single_once uses single-care-on copy', () {
      final text = AwayPlanScheduleCopy.plannedCareScheduleLine(
        l,
        _item(kind: PlannedCareKind.singleOnce, scheduledDate: '2026-10-02'),
      );
      expect(text, l.awayPlanningEventSingleCareOn(displayDate('2026-10-02')));
    });

    test('indeterminate_pending maps reason copy', () {
      final text = AwayPlanScheduleCopy.plannedCareScheduleLine(
        l,
        _item(
          kind: PlannedCareKind.indeterminatePending,
          reason: 'from_completion_pending',
        ),
      );
      expect(text, l.awayPlanningIndeterminatePending);
    });
  });

  group('plannedCareDetailLines', () {
    test(
      'recurring_calendar shows next due date when at most one time of day',
      () {
        final lines = AwayPlanScheduleCopy.plannedCareDetailLines(
          l,
          _item(
            kind: PlannedCareKind.recurringCalendar,
            nextDueDate: '2026-10-02',
            timesOfDay: const ['08:00'],
          ),
        );
        expect(lines, [
          l.awayPlanningEventNextDueDate(displayDate('2026-10-02')),
          l.awayPlanningEventTimeOfDay('08:00'),
        ]);
      },
    );

    test('skips legacy next due when open occurrence is present', () {
      final lines = AwayPlanScheduleCopy.plannedCareDetailLines(
        l,
        _item(
          kind: PlannedCareKind.recurringCalendar,
          nextDueDate: '2026-10-02',
          openOccurrence: const PlannedCareOpenOccurrence(
            scheduledDate: '2026-09-28',
            openStatus: 'overdue',
          ),
        ),
      );
      expect(lines, isEmpty);
    });

    test('skips legacy next due when in_window is present', () {
      final lines = AwayPlanScheduleCopy.plannedCareDetailLines(
        l,
        _item(
          kind: PlannedCareKind.recurringCalendar,
          nextDueDate: '2026-10-02',
          inWindow: const PlannedCareInWindow(
            firstDate: '2026-10-03',
            lastDate: '2026-10-03',
            count: 1,
            dateBasis: 'planned',
          ),
        ),
      );
      expect(lines, isEmpty);
    });

    test(
      'recurring_calendar omits next due date when multiple times of day',
      () {
        final lines = AwayPlanScheduleCopy.plannedCareDetailLines(
          l,
          _item(
            kind: PlannedCareKind.recurringCalendar,
            nextDueDate: '2026-10-02',
            timesOfDay: const ['08:00', '20:00'],
          ),
        );
        expect(lines, [
          l.awayPlanningEventTimeOfDay('08:00'),
          l.awayPlanningEventTimeOfDay('20:00'),
        ]);
      },
    );
  });

  group('plannedCareHandoverLine', () {
    test('includes open and in-window segments for PDF parity', () {
      final line = AwayPlanScheduleCopy.plannedCareHandoverLine(
        l,
        _item(
          kind: PlannedCareKind.recurringChain,
          openOccurrence: const PlannedCareOpenOccurrence(
            scheduledDate: '2026-09-01',
            openStatus: 'overdue',
          ),
          inWindow: const PlannedCareInWindow(
            firstDate: '2026-10-04',
            lastDate: '2026-10-04',
            count: 1,
            dateBasis: 'estimated',
          ),
        ),
      );
      expect(line, contains(l.urgencyOverdue));
      expect(line, contains(l.awayPlanningEstimatedOn(displayDate('2026-10-04'))));
    });
  });
}
