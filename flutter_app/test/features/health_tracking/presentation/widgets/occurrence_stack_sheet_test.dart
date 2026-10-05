import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_repository.dart';
import 'package:pet_profile_app/features/health_tracking/domain/occurrence_scheduling.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import '../../../../helpers/fakes.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/occurrence_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/occurrence_care_actions.dart';
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
  String status = 'pending',
}) {
  return HealthOccurrence(
    id: id,
    entryId: 'entry-1',
    scheduledDate: date,
    scheduledTime: time,
    status: status,
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

Widget _buildCareActionsHarness({
  required List<HealthOccurrence> occurrences,
  required ValueChanged<OccurrenceMarkDoneResult?> onResult,
  HealthRepository? repository,
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => FakeAuthNotifier()),
      entryOccurrencesProvider(
        _entry.id,
      ).overrideWith((ref) async => occurrences),
      if (repository != null)
        healthRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () async {
                onResult(
                  await OccurrenceCareActions.showMarkDoneFlow(
                    context,
                    ref,
                    _entry,
                  ),
                );
              },
              child: const Text('Open care actions'),
            ),
          ),
        ),
      ),
    ),
  );
}

class _RecordingHealthRepository implements HealthRepository {
  final completedOccurrenceIds = <String>[];
  final skipEarlierMissedValues = <bool>[];
  var skipMissedCalls = 0;

  @override
  Future<HealthOccurrence> completeOccurrence(
    String entryId,
    String occurrenceId, {
    String notes = '',
    DateTime? completedOn,
    bool skipEarlierMissed = false,
  }) async {
    completedOccurrenceIds.add(occurrenceId);
    skipEarlierMissedValues.add(skipEarlierMissed);
    return _occ(id: occurrenceId, date: completedOn ?? DateTime.now());
  }

  @override
  Future<List<HealthEntry>> getEntries({
    String? petId,
    HealthEntryType? type,
  }) async {
    return [_entry];
  }

  @override
  Future<int> skipMissedOccurrences(String entryId) async {
    skipMissedCalls++;
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Due today'), findsOneWidget);
      expect(find.text('Coming up'), findsOneWidget);
      expect(find.text('Record the latest date'), findsOneWidget);
      expect(find.text('Skip all overdue'), findsOneWidget);
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

  group('OccurrenceCareActions.showMarkDoneFlow', () {
    testWidgets(
      'due-today and future pending occurrences use the normal date flow',
      (tester) async {
        final today = calendarDateOnly(DateTime.now());
        final tomorrow = today.add(const Duration(days: 1));
        OccurrenceMarkDoneResult? result;

        await tester.pumpWidget(
          _buildCareActionsHarness(
            occurrences: [
              _occ(id: 'today', date: today),
              _occ(id: 'future', date: tomorrow),
            ],
            onResult: (value) => result = value,
          ),
        );
        await tester.tap(find.text('Open care actions'));
        await tester.pumpAndSettle();

        expect(
          find.text('Record earlier dates for Morning meds'),
          findsNothing,
        );

        expect(result, isNotNull);
        expect(result!.completedOn, calendarDateOnly(DateTime.now()));
        expect(result!.occurrenceId, 'today');
      },
    );

    testWidgets(
      'completed today history does not make one due dose look like a stack',
      (tester) async {
        final today = calendarDateOnly(DateTime.now());
        final tomorrow = today.add(const Duration(days: 1));
        OccurrenceMarkDoneResult? result;

        await tester.pumpWidget(
          _buildCareActionsHarness(
            occurrences: [
              _occ(id: 'completed-today', date: today, status: 'completed'),
              _occ(id: 'today-pending', date: today),
              _occ(id: 'future-pending', date: tomorrow),
            ],
            onResult: (value) => result = value,
          ),
        );
        await tester.tap(find.text('Open care actions'));
        await tester.pumpAndSettle();

        expect(
          find.text('Record earlier dates for Morning meds'),
          findsNothing,
        );
        expect(find.text('Overdue'), findsNothing);

        expect(result, isNotNull);
        expect(result!.occurrenceId, 'today-pending');
      },
    );

    testWidgets(
      'multiple due-today doses open stack without treating future doses as missed',
      (tester) async {
        final now = DateTime.now();
        final today = calendarDateOnly(now);
        final tomorrow = today.add(const Duration(days: 1));
        final firstDoseTime = now.add(const Duration(minutes: 1));
        final secondDoseTime = now.add(const Duration(minutes: 2));
        final timedHeadIsAvailable = calendarDateOnly(secondDoseTime) == today;
        String formatTime(DateTime date) =>
            '${date.hour.toString().padLeft(2, '0')}:'
            '${date.minute.toString().padLeft(2, '0')}';
        final repository = _RecordingHealthRepository();
        OccurrenceMarkDoneResult? result;

        await tester.pumpWidget(
          _buildCareActionsHarness(
            occurrences: [
              _occ(
                id: 'today-first',
                date: today,
                time: timedHeadIsAvailable ? formatTime(firstDoseTime) : null,
              ),
              _occ(
                id: 'today-second',
                date: today,
                time: timedHeadIsAvailable ? formatTime(secondDoseTime) : null,
              ),
              _occ(id: 'future-first', date: tomorrow),
              _occ(id: 'future-second', date: tomorrow),
            ],
            repository: repository,
            onResult: (value) => result = value,
          ),
        );
        await tester.tap(find.text('Open care actions'));
        await tester.pumpAndSettle();

        expect(
          find.text('Record earlier dates for Morning meds'),
          findsOneWidget,
        );
        expect(find.text('Overdue'), findsNothing);
        expect(find.text('Due today'), findsOneWidget);
        expect(find.text('Coming up'), findsOneWidget);
        expect(find.text('Mark as completed'), findsNothing);

        await tester.tap(find.byKey(const Key('occurrence_record_head')));
        await tester.pumpAndSettle();

        expect(repository.completedOccurrenceIds, hasLength(1));
        expect([
          'today-first',
          'today-second',
        ], contains(repository.completedOccurrenceIds.single));
        if (timedHeadIsAvailable) {
          expect(repository.completedOccurrenceIds, ['today-first']);
        }
        expect(repository.skipEarlierMissedValues, [false]);
        expect(repository.skipMissedCalls, 0);
        expect(result?.occurrenceId, repository.completedOccurrenceIds.single);
      },
    );

    testWidgets('a genuinely missed occurrence still opens the stack', (
      tester,
    ) async {
      final today = calendarDateOnly(DateTime.now());
      final yesterday = today.subtract(const Duration(days: 1));
      OccurrenceMarkDoneResult? result;

      await tester.pumpWidget(
        _buildCareActionsHarness(
          occurrences: [
            _occ(id: 'missed', date: yesterday),
            _occ(id: 'today', date: today),
          ],
          onResult: (value) => result = value,
        ),
      );
      await tester.tap(find.text('Open care actions'));
      await tester.pumpAndSettle();

      expect(
        find.text('Record earlier dates for Morning meds'),
        findsOneWidget,
      );
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Due today'), findsOneWidget);
      expect(find.text('Mark as completed'), findsNothing);
      expect(result, isNull);
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
