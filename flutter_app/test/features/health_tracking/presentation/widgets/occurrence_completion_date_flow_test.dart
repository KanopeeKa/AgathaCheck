import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/occurrence_completion_date_flow.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

HealthOccurrence _occ(DateTime scheduled, {bool missed = false}) {
  return HealthOccurrence(
    id: 'occ-1',
    entryId: 'entry-1',
    scheduledDate: scheduled,
    status: 'pending',
    missed: missed,
  );
}

void main() {
  group('resolveCompletedOnForOccurrence', () {
    testWidgets('returns today for due-today occurrence without sheet', (
      tester,
    ) async {
      final now = DateTime(2026, 3, 15, 14, 0);
      final today = calendarDateOnly(now);
      DateTime? result;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await resolveCompletedOnForOccurrence(
                    context,
                    _occ(today, missed: false),
                    now: now,
                  );
                },
                child: const Text('go'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(result, today);
      expect(find.text('When was this done?'), findsNothing);
    });

    testWidgets('opens overdue sheet for missed occurrence', (tester) async {
      final now = DateTime(2026, 3, 15, 14, 0);
      final yesterday = calendarDateOnly(now).subtract(const Duration(days: 1));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  resolveCompletedOnForOccurrence(
                    context,
                    _occ(yesterday, missed: true),
                    now: now,
                  );
                },
                child: const Text('go'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('When was this done?'), findsOneWidget);
      expect(find.byKey(const Key('overdue_completion_today')), findsOneWidget);
    });
  });
}
