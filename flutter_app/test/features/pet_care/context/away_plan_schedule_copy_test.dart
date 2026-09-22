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
  );
}

void main() {
  late AppLocalizations l;

  String displayDate(String iso) =>
      formatCalendarDateDisplay(parseCalendarDate(iso)!);

  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('plannedCareRowTitle', () {
    test('prefixes conditional rows', () {
      expect(
        AwayPlanScheduleCopy.plannedCareRowTitle(
          _item(
            kind: PlannedCareKind.recurringCalendar,
            certainty: 'conditional_on_future_completion',
          ),
        ),
        '~ Daily pill',
      );
    });
  });

  group('plannedCareScheduleLine matrix', () {
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
        _item(
          kind: PlannedCareKind.recurringChain,
          frequency: 'weekly',
        ),
      );
      expect(
        text,
        l.awayPlanningEventRepeatsFromCompletion(1, l.weekly),
      );
    });

    test('single_once uses single-care-on copy', () {
      final text = AwayPlanScheduleCopy.plannedCareScheduleLine(
        l,
        _item(
          kind: PlannedCareKind.singleOnce,
          scheduledDate: '2026-10-02',
        ),
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
    test('recurring_calendar shows next due date when at most one time of day', () {
      final lines = AwayPlanScheduleCopy.plannedCareDetailLines(
        l,
        _item(
          kind: PlannedCareKind.recurringCalendar,
          nextDueDate: '2026-10-02',
          timesOfDay: const ['08:00'],
        ),
      );
      expect(
        lines,
        [
          l.awayPlanningEventNextDueDate(displayDate('2026-10-02')),
          l.awayPlanningEventTimeOfDay('08:00'),
        ],
      );
    });

    test('recurring_calendar omits next due date when multiple times of day', () {
      final lines = AwayPlanScheduleCopy.plannedCareDetailLines(
        l,
        _item(
          kind: PlannedCareKind.recurringCalendar,
          nextDueDate: '2026-10-02',
          timesOfDay: const ['08:00', '20:00'],
        ),
      );
      expect(
        lines,
        [
          l.awayPlanningEventTimeOfDay('08:00'),
          l.awayPlanningEventTimeOfDay('20:00'),
        ],
      );
    });

    test('renders one time-of-day line per distinct time', () {
      final lines = AwayPlanScheduleCopy.plannedCareDetailLines(
        l,
        _item(
          kind: PlannedCareKind.recurringCalendar,
          timesOfDay: const ['08:00', '20:00'],
        ),
      );
      expect(
        lines,
        [
          l.awayPlanningEventTimeOfDay('08:00'),
          l.awayPlanningEventTimeOfDay('20:00'),
        ],
      );
    });
  });
}
