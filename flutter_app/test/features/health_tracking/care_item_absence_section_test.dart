import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/health_tracking/data/models/health_entry_absence_context_model.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/care_item_absence_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/screens/care_item_detail/care_item_absence_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('CareItemAbsenceSection shows keep-date action when not reviewed', (
    tester,
  ) async {
    const entryId = 'entry-1';
    final context = HealthEntryAbsenceContext(
      healthEntryId: entryId,
      petId: 'pet-1',
      absences: const [
        HealthEntryAbsenceSlice(
          plannedAbsenceId: 'abs-1',
          startsOn: '2026-10-25',
          endsOn: '2026-10-30',
          affected: true,
          uiState: 'not_reviewed',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          careItemAbsenceContextProvider(entryId).overrideWith(
            (ref) async => context,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: CareItemAbsenceSection(entryId: entryId, muted: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('care_item_absence_section')), findsOneWidget);
    expect(find.byKey(const Key('care_item_absence_keep_date')), findsOneWidget);
  });
}
