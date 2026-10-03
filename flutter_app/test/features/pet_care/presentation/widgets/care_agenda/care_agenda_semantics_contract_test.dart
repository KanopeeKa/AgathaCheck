import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/pet_care/presentation/widgets/care_agenda/care_agenda_row_tile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/care_schedule_entries.dart';

void main() {
  testWidgets('care agenda row exposes stable semantics identifiers', (
    tester,
  ) async {
    final entry = scheduledEntry(
      id: 'entry-1',
      name: 'Heartworm',
      open: [
        OpenOccurrence(
          id: 'occ-1',
          date: careToday(),
          status: CareOccurrenceStatus.due,
          origin: CareOccurrenceOrigin.schedule,
        ),
      ],
    );
    final row = buildCareAgenda([entry], (e) => e.schedule!).rows.first;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CareAgendaRowTile(row: row, onOpen: () {}, onDone: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsIdentifier('care_agenda_row_entry-1'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('pet_care_action_done_entry-1'),
      findsOneWidget,
    );
  });
}
