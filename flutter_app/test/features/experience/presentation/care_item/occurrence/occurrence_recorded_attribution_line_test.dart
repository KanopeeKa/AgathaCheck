import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/care_item/domain/care_occurrence.dart';
import 'package:pet_profile_app/features/care_item/domain/occurrence_detail.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/occurrence/occurrence_recorded_attribution_line.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

CareOccurrence _occ({
  required CareOccurrenceStatus status,
  bool isOpen = false,
  DateTime? markedAt,
  String? markedByName,
  String notes = '',
}) {
  return CareOccurrence(
    id: 'occ-1',
    date: DateTime(2026, 11, 7),
    status: status,
    origin: CareOccurrenceOrigin.computed,
    isOpen: isOpen,
    markedAt: markedAt,
    markedByName: markedByName,
    notes: notes,
  );
}

void main() {
  testWidgets('shows recorded line for done with name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OccurrenceRecordedAttributionLine(
          occurrence: _occ(
            status: CareOccurrenceStatus.done,
            markedAt: DateTime(2026, 11, 3, 22, 7),
            markedByName: 'Frederique Prevost',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Recorded 03 Nov 26 at 22:07 by Frederique Prevost'),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.identifier == 'occurrence_recorded_attribution',
      ),
      findsOneWidget,
    );
  });

  testWidgets('skipped uses unknown user when name missing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OccurrenceRecordedAttributionLine(
          occurrence: _occ(
            status: CareOccurrenceStatus.skipped,
            markedAt: DateTime(2026, 11, 3, 10, 0),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Unknown user'), findsOneWidget);
  });

  testWidgets('hides for system-closed not recorded', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OccurrenceRecordedAttributionLine(
          occurrence: _occ(
            status: CareOccurrenceStatus.notRecorded,
            markedAt: DateTime(2026, 11, 3),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OccurrenceRecordedAttributionLine), findsOneWidget);
    expect(find.textContaining('Recorded'), findsNothing);
  });

  testWidgets('notes on second line', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OccurrenceRecordedAttributionLine(
          occurrence: _occ(
            status: CareOccurrenceStatus.done,
            markedAt: DateTime(2026, 11, 3, 22, 7),
            markedByName: 'Alex',
            notes: 'Gave with food',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Gave with food'), findsOneWidget);
  });
}
