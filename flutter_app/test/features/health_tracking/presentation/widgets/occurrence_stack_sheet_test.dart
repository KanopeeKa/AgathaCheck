import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/domain/occurrence_scheduling.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/occurrence_stack_sheet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

final _entry = HealthEntry(
  id: 'entry-1',
  petId: 'pet-1',
  name: 'Morning meds',
  type: HealthEntryType.medication,
  frequency: HealthFrequency.daily,
  startDate: DateTime(2024, 1, 1),
  nextDueDate: DateTime.now(),
);

HealthOccurrence _occ({
  required String id,
  required DateTime date,
  String? time,
}) {
  return HealthOccurrence(
    id: id,
    entryId: 'entry-1',
    scheduledDate: date,
    scheduledTime: time,
    status: 'pending',
  );
}

Widget _buildSheet({
  required List<HealthOccurrence> occurrences,
  Future<void> Function(String, DateTime, bool)? onRecordHead,
  Future<void> Function()? onSkipAllMissed,
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: OccurrenceStackSheet(
        entry: _entry,
        occurrences: occurrences,
        onRecordHead: onRecordHead ?? (_, __, ___) async {},
        onSkipAllMissed: onSkipAllMissed ?? () async {},
      ),
    ),
  );
}

void main() {
  group('OccurrenceStackSheet', () {
    testWidgets('shows missed, due today, and coming up zones', (tester) async {
      final now = DateTime.now();
      final today = calendarDateOnly(now);
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));
      // Use a late time today so the occurrence stays in "Due today" after noon.
      const todayTime = '23:59';

      await tester.pumpWidget(
        _buildSheet(
          occurrences: [
            _occ(id: 'missed', date: yesterday, time: '08:00'),
            _occ(id: 'today', date: today, time: todayTime),
            _occ(id: 'later', date: tomorrow, time: '08:00'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Missed'), findsOneWidget);
      expect(find.text('Due today'), findsOneWidget);
      expect(find.text('Coming up'), findsOneWidget);
      expect(find.text('Record latest dose'), findsOneWidget);
      expect(find.text('Skip all missed'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
    });

    testWidgets('skip earlier missed checkbox only when multiple missed', (
      tester,
    ) async {
      final today = calendarDateOnly(DateTime.now());
      final yesterday = today.subtract(const Duration(days: 1));

      await tester.pumpWidget(
        _buildSheet(
          occurrences: [
            _occ(id: 'missed-a', date: yesterday, time: '08:00'),
            _occ(id: 'missed-b', date: yesterday, time: '20:00'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('occurrence_skip_earlier_missed')),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _buildSheet(
          occurrences: [_occ(id: 'missed-a', date: yesterday, time: '08:00')],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('occurrence_skip_earlier_missed')),
        findsNothing,
      );
    });

    testWidgets('not now dismisses without persisting', (tester) async {
      var recorded = false;
      final today = calendarDateOnly(DateTime.now());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await showOccurrenceStackSheet(
                      context,
                      entry: _entry,
                      occurrences: [
                        _occ(id: 'today', date: today, time: '08:00'),
                        _occ(id: 'today-2', date: today, time: '20:00'),
                      ],
                      onRecordHead: (_, __, ___) async {
                        recorded = true;
                      },
                      onSkipAllMissed: () async {},
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('occurrence_not_now')));
      await tester.pumpAndSettle();

      expect(recorded, isFalse);
    });
  });

  group('summarizeOpenOccurrences integration', () {
    test('record head targets missed LIFO head', () {
      final today = calendarDateOnly(DateTime.now());
      final yesterday = today.subtract(const Duration(days: 1));
      final now = DateTime(today.year, today.month, today.day, 7, 0);

      final open = [
        _occ(id: 'missed-old', date: yesterday, time: '08:00'),
        _occ(id: 'missed-new', date: yesterday, time: '20:00'),
        _occ(id: 'today', date: today, time: '20:00'),
      ];

      final summary = summarizeOpenOccurrences(open, now);
      expect(summary.missedHead?.id, 'missed-new');
      expect(summary.nextHead?.id, 'today');
    });
  });
}
