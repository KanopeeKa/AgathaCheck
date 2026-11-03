import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/absence_care_plan.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/care_period_coverage.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/planned_absence.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/planned_absence_pet_carer.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/providers/care_context_providers.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/screens/pet_away_plan_screen.dart';
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
    petIds: ['pet-1'],
    isOwnAbsence: true,
    petCarers: [
      PlannedAbsencePetCarer(
        petId: 'pet-1',
        carerKind: 'note_only',
        carerName: 'Tom',
        carerState: 'set',
      ),
    ],
  );

  const coverage = CarePeriodCoverageResult(
    startsOn: '2026-10-01',
    endsOn: '2026-10-05',
    projectionStatus: CarePeriodProjectionStatus.complete,
    items: [
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
    coverage: CarePeriodCoverageSummary(
      policyVersion: '1',
      coverageState: CarePeriodCoverageState.hasItemsToReview,
      reasonCodes: [],
      reassuranceAvailable: true,
    ),
    plannedCareItems: [
      PlannedCareItem(
        kind: PlannedCareKind.recurringCalendar,
        healthEntryId: 'e1',
        name: 'Daily pill',
        type: 'medication',
        careFamily: 'medication',
      ),
    ],
  );

  const pet = Pet(id: 'pet-1', name: 'Luna', species: 'dog', breed: 'Mixed');

  Widget buildScreen({PlannedAbsence? overrideAbsence}) {
    return ProviderScope(
      overrides: [
        plannedAbsenceDetailProvider(
          'abs-1',
        ).overrideWith((ref) async => overrideAbsence ?? absence),
        allPetsIncludingOrgProvider.overrideWith((ref) async => [pet]),
        carePeriodCoverageProvider((
          petId: 'pet-1',
          startsOn: '2026-10-01',
          endsOn: '2026-10-05',
          plannedAbsenceId: 'abs-1',
        )).overrideWith((ref) async => coverage),
        absenceCarePlanProvider('abs-1').overrideWith(
          (ref) async => const AbsenceCarePlan(
            absenceId: 'abs-1',
            today: '2026-09-20',
            startsOn: '2026-10-01',
            endsOn: '2026-10-05',
            pets: [
              AbsenceCarePlanPet(
                petId: 'pet-1',
                suggestions: [],
                carerTasks: CarePlannerCarerTasks(count: 0, byEntry: []),
              ),
            ],
          ),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/pc/away/:id/pets/:petId',
              builder: (_, state) => PetAwayPlanScreen(
                absenceId: state.pathParameters['id']!,
                petId: state.pathParameters['petId']!,
              ),
            ),
          ],
          initialLocation: '/pc/away/abs-1/pets/pet-1',
        ),
      ),
    );
  }

  testWidgets('pet away plan shows carer, notes, and planned care', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pet_away_plan_page_pet-1')), findsOneWidget);
    expect(find.text("Who's caring"), findsOneWidget);
    expect(find.textContaining('Tom'), findsOneWidget);
    expect(find.byKey(const Key('away_plan_see_absence')), findsOneWidget);
    expect(find.byKey(const Key('away_plan_pet_notes_pet-1')), findsOneWidget);
  });
}
