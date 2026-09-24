import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/recurrence_anchor.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/reschedule_occurrence_sheet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('reschedule sheet shows gap warning and preview', (tester) async {
    final entry = HealthEntry(
      id: 'e1',
      petId: 'p1',
      name: 'Monthly med',
      type: HealthEntryType.medication,
      frequency: HealthFrequency.monthly,
      frequencyInterval: 1,
      startDate: parseCalendarDate('2026-01-01')!,
      recurrenceAnchor: RecurrenceAnchor.fromDueDate,
    );
    final occurrence = HealthOccurrence(
      id: 'occ-1',
      entryId: 'e1',
      scheduledDate: parseCalendarDate('2026-03-01')!,
      status: 'pending',
    );
    final past = [
      HealthOccurrence(
        id: 'past-1',
        entryId: 'e1',
        scheduledDate: parseCalendarDate('2026-02-01')!,
        status: 'completed',
        completedOn: parseCalendarDate('2026-02-01'),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showRescheduleOccurrenceSheet(
                  context,
                  entry: entry,
                  occurrence: occurrence,
                  pastOccurrences: past,
                  initialDate: parseCalendarDate('2026-03-15'),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l.rescheduleActionLabel), findsWidgets);
    expect(find.textContaining('days after the last one'), findsOneWidget);
    expect(find.textContaining('Next ones:'), findsOneWidget);
  });

  testWidgets(
    'confirming without opening picker returns wire date matching display',
    (tester) async {
      final today = calendarDateOnly(DateTime.now());
      final todayWire = toCalendarDateString(today)!;

      final entry = HealthEntry(
        id: 'e1',
        petId: 'p1',
        name: 'Daily med',
        type: HealthEntryType.medication,
        frequency: HealthFrequency.once,
        frequencyInterval: 1,
        startDate: parseCalendarDate('2026-01-01')!,
      );
      final occurrence = HealthOccurrence(
        id: 'occ-today',
        entryId: 'e1',
        scheduledDate: today,
        status: 'pending',
      );

      DateTime? confirmed;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  confirmed = await showRescheduleOccurrenceSheet(
                    context,
                    entry: entry,
                    occurrence: occurrence,
                    pastOccurrences: const [],
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(formatCalendarDateDisplay(today)), findsOneWidget);

      final l = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(
        find.widgetWithText(FilledButton, l.rescheduleActionLabel),
      );
      await tester.pumpAndSettle();

      expect(confirmed, isNotNull);
      expect(toCalendarDateString(confirmed), todayWire);
      expect(
        formatCalendarDateDisplay(confirmed!),
        formatCalendarDateDisplay(today),
      );
    },
  );
}
