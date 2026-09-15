import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/away_plan_readiness.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/care_period_coverage.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/planned_absence.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/planned_absence_pet_carer.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/providers/care_context_providers.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/screens/planned_absence_plan_screen.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  const absence = PlannedAbsence(
    id: 'abs-1',
    userId: 'user-1',
    startsOn: '2026-10-01',
    endsOn: '2026-10-05',
    provenance: 'user_declared',
    status: 'active',
    petIds: const ['pet-1'],
    petCarers: const [
      PlannedAbsencePetCarer(
        petId: 'pet-1',
        carerKind: 'note_only',
        carerName: 'Tom',
      ),
    ],
  );

  const readiness = AwayPlanReadiness(
    carerCoverage: const CarerCoverageFact(
      state: 'all_have_carers',
      petsWithCarer: 1,
      petsTotal: 1,
      copyKey: 'awayPlanningCarerCoverageAllHaveCarers',
    ),
    careCoverage: const CareCoverageFact(
      policyVersion: '1',
      coverageState: 'has_items_to_review',
      reasonCodes: const [],
      reassuranceAvailable: true,
      copyKey: 'careContextCoverageHasItemsToReview',
      copyCount: 1,
    ),
    tileCopy: const AwayPlanTileCopy(
      source: 'care_coverage',
      copyKey: 'careContextCoverageHasItemsToReview',
      copyParams: const {'count': 1},
    ),
  );

  const coverage = CarePeriodCoverageResult(
    startsOn: '2026-10-01',
    endsOn: '2026-10-05',
    projectionStatus: CarePeriodProjectionStatus.complete,
    uncertainties: const [],
    items: const [
      CarePeriodProjectionItem(
        healthEntryId: 'e1',
        scheduledDate: '2026-10-02',
        status: 'pending',
        source: 'projected',
        name: 'Daily pill',
        type: 'medication',
        careFamily: 'medication',
      ),
    ],
    coverage: const CarePeriodCoverageSummary(
      policyVersion: '1',
      coverageState: CarePeriodCoverageState.hasItemsToReview,
      reasonCodes: const [],
      reassuranceAvailable: true,
    ),
    routineItems: const [
      CarePeriodRoutineItem(
        healthEntryId: 'e1',
        name: 'Daily pill',
        type: 'medication',
        careFamily: 'medication',
        scheduledTime: '08:00',
        certainty: 'complete',
        occurrenceCount: 4,
        status: 'pending',
        firstScheduledDate: '2026-10-01',
        lastScheduledDate: '2026-10-04',
      ),
    ],
    datedItems: const [],
  );

  const pet = Pet(id: 'pet-1', name: 'Luna', species: 'dog', breed: 'Mixed');

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        plannedAbsenceDetailProvider(
          'abs-1',
        ).overrideWith((ref) async => absence),
        awayPlanReadinessProvider(
          'abs-1',
        ).overrideWith((ref) async => readiness),
        allPetsIncludingOrgProvider.overrideWith((ref) async => [pet]),
        carePeriodCoverageProvider((
          petId: 'pet-1',
          startsOn: '2026-10-01',
          endsOn: '2026-10-05',
        )).overrideWith((ref) async => coverage),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/pc/away/:id',
              builder: (_, state) => PlannedAbsencePlanScreen(
                absenceId: state.pathParameters['id']!,
              ),
            ),
          ],
          initialLocation: '/pc/away/abs-1',
        ),
      ),
    );
  }

  testWidgets('renders plan page sections without reschedule affordance', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('away_plan_page')), findsOneWidget);
    expect(find.text("Who's caring"), findsOneWidget);
    expect(find.text('Care during your absence'), findsOneWidget);
    expect(find.text('Luna'), findsWidgets);
    expect(find.text('Routine care'), findsOneWidget);
    expect(find.textContaining('Tom'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Plan details'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Plan details'), findsOneWidget);
    expect(find.textContaining('Reschedule'), findsNothing);
    expect(find.textContaining('Move'), findsNothing);
  });
}
