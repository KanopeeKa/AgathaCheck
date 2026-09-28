import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/health_tracking/data/models/health_entry_absence_context_model.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/care_item_absence_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/screens/care_item_detail/care_item_absence_section.dart';
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

  testWidgets('CareItemAbsenceSection shows keep and review actions', (
    tester,
  ) async {
    const entryId = 'entry-1';
    final context = HealthEntryAbsenceContext(
      healthEntryId: entryId,
      petId: 'pet-1',
      absences: [
        HealthEntryAbsenceSlice(
          plannedAbsenceId: 'abs-1',
          startsOn: '2026-10-25',
          endsOn: '2026-10-30',
          affected: true,
          uiState: 'not_reviewed',
          petCarer: const HealthEntryAbsenceLookedAfterBy(
            carerKind: 'note_only',
            carerName: 'Jamie',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          careItemAbsenceContextProvider(
            entryId,
          ).overrideWith((ref) async => context),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareItemAbsenceSection(entry: entry, muted: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.byKey(const Key('care_item_absence_section')), findsOneWidget);
    expect(
      find.byKey(const Key('care_item_absence_keep_date')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('care_item_absence_review_date')),
      findsOneWidget,
    );
    expect(find.text(l.careItemAbsenceKeepWithCarer('Jamie')), findsOneWidget);
    expect(find.text(l.careItemAbsenceReviewDateAction), findsOneWidget);
    expect(find.text(l.careItemAbsenceNothingNeeded), findsNothing);
  });

  testWidgets('CareItemAbsenceSection uses keep-during-absence without carer', (
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
          careItemAbsenceContextProvider(
            entryId,
          ).overrideWith((ref) async => context),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareItemAbsenceSection(entry: entry, muted: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l.careItemAbsenceKeepDuringAbsence), findsOneWidget);
  });
}
