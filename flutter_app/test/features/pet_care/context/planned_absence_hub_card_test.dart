import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/planned_absence.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/widgets/planned_absence_hub_card.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('zero pets', (t) async {
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PlannedAbsenceHubCard(
            absence: PlannedAbsence(
              id: '1',
              userId: 'u',
              startsOn: '2026-09-10',
              endsOn: '2026-09-17',
              provenance: 'user_declared',
              status: 'active',
              petIds: const [],
            ),
            petsById: const {},
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final l = AppLocalizations.of(
      t.element(find.byType(PlannedAbsenceHubCard)),
    )!;
    expect(find.text(l.careContextAwayPetsRequired), findsOneWidget);
  });
  testWidgets('passed away', (t) async {
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PlannedAbsenceHubCard(
            absence: PlannedAbsence(
              id: '1',
              userId: 'u',
              startsOn: '2026-09-10',
              endsOn: '2026-09-17',
              provenance: 'user_declared',
              status: 'active',
              petIds: const ['p1'],
            ),
            petsById: {
              'p1': Pet(
                id: 'p1',
                name: 'Buddy',
                species: 'dog',
                passedAway: true,
              ),
            },
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final l = AppLocalizations.of(
      t.element(find.byType(PlannedAbsenceHubCard)),
    )!;
    expect(
      find.text('Buddy (${l.placementOutcomePassedAway})'),
      findsOneWidget,
    );
    expect(find.text(l.careContextAwayPetsStepBody), findsOneWidget);
  });
}
