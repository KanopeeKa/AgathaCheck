import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/occurrence_review_sheet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  final entry = HealthEntry(
    id: 'entry-1',
    petId: 'pet-1',
    name: 'Flea treatment',
    type: HealthEntryType.medication,
    frequency: HealthFrequency.monthly,
    startDate: DateTime(2026, 1, 1),
    nextDueDate: DateTime(2026, 10, 6),
  );

  final occurrence = HealthOccurrence(
    id: 'occ-1',
    entryId: 'entry-1',
    scheduledDate: parseCalendarDate('2026-10-06')!,
    status: 'pending',
  );

  testWidgets('review sheet shows title, date line, and action keys', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: OccurrenceReviewSheet(
              entry: entry,
              occurrence: occurrence,
            ),
          ),
        ),
      ),
    );

    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.byKey(const Key('occurrence_review_sheet')), findsOneWidget);
    expect(find.text(l.careItemOccurrenceReviewTitle), findsOneWidget);
    expect(
      find.text(
        l.careItemAbsenceReviewDate(
          formatCalendarDateDisplay(occurrence.scheduledDate),
        ),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('occurrence_review_change_date')), findsOneWidget);
    expect(find.byKey(const Key('occurrence_review_skip')), findsOneWidget);
    expect(find.text(l.rescheduleActionLabel), findsOneWidget);
    expect(find.text(l.skipOccurrence), findsOneWidget);
  });
}
