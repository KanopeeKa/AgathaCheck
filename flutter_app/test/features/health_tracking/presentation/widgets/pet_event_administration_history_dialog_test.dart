import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/pet_event_administration_history_dialog.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('history dialog lists pills and uses History title', (
    tester,
  ) async {
    final rows = [
      HealthOccurrence(
        id: 'h1',
        entryId: 'entry-1',
        scheduledDate: DateTime(2026, 3, 1),
        status: 'completed',
        completedOn: DateTime(2026, 3, 1),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showPetEventPastHistoryDialog(
                context,
                occurrences: rows,
                petId: 'pet-1',
                muted: false,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    expect(
      find.byKey(const Key('pet_event_past_occurrence_h1')),
      findsOneWidget,
    );
    expect(find.textContaining('Administration'), findsNothing);
  });
}
