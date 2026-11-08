import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/past_occurrence_history_pill.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('done pill shows due and close dates without status words', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PastOccurrenceHistoryPill(
            occurrence: HealthOccurrence(
              id: 'o1',
              entryId: 'e1',
              scheduledDate: DateTime(2026, 11, 7),
              scheduledTime: '09:00',
              status: 'completed',
              completedOn: DateTime(2026, 11, 7),
            ),
            muted: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('07 Nov 26 at 09:00'), findsOneWidget);
    expect(find.text('Done'), findsNothing);
    expect(find.textContaining('Skipped'), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('not recorded pill has icon only on the right', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PastOccurrenceHistoryPill(
            occurrence: HealthOccurrence(
              id: 'o2',
              entryId: 'e1',
              scheduledDate: DateTime(2026, 11, 5),
              status: 'not_recorded',
            ),
            muted: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.text('Not recorded'), findsNothing);
  });
}
