import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/pet_care/context/data/datasources/care_context_remote_datasource.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/absence_care_plan.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/away_plan_readiness.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/care_period_coverage.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/carer_candidate.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/planned_absence.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/planned_absence_pet_carer.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/repositories/care_context_repository.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/providers/care_context_providers.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/screens/planned_absence_plan_screen.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class _FakeCareContextRepository implements CareContextRepository {
  _FakeCareContextRepository({
    this.candidates = const [],
    this.updateResult,
    this.updateThrows,
  });

  List<CarerCandidate> candidates;
  PlannedAbsence? Function(String absenceId)? updateResult;
  Object? Function()? updateThrows;
  List<Map<String, dynamic>> savedPetCarers = [];
  int updateCallCount = 0;
  int getCarerCandidatesCallCount = 0;

  @override
  Future<List<CarerCandidate>> getCarerCandidates(String petId) async {
    getCarerCandidatesCallCount++;
    return candidates;
  }

  @override
  Future<PlannedAbsence> updatePetCarers({
    required String absenceId,
    required List<Map<String, dynamic>> petCarers,
  }) async {
    updateCallCount++;
    final throws = updateThrows?.call();
    if (throws != null) throw throws;
    savedPetCarers.add(petCarers.first);
    final result = updateResult?.call(absenceId);
    return result ??
        const PlannedAbsence(
          id: 'abs-1',
          userId: 'user-1',
          startsOn: '2026-10-01',
          endsOn: '2026-10-05',
          provenance: 'user_declared',
          status: 'active',
          petIds: ['pet-1'],
          petCarers: [],
        );
  }

  @override
  Future<CarePeriodCoverageResult> getCarePeriodCoverage({
    required String petId,
    required String startsOn,
    required String endsOn,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CreatePlannedAbsenceResult> createPlannedAbsence({
    required String startsOn,
    required String endsOn,
    required List<String> petIds,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<PlannedAbsence>> listPlannedAbsences({String scope = 'all'}) {
    throw UnimplementedError();
  }

  @override
  Future<PlannedAbsence> getPlannedAbsence(String absenceId) async =>
      const PlannedAbsence(
        id: 'abs-1',
        userId: 'user-1',
        startsOn: '2026-10-01',
        endsOn: '2026-10-05',
        provenance: 'user_declared',
        status: 'active',
        petIds: ['pet-1'],
        petCarers: [PlannedAbsencePetCarer(petId: 'pet-1')],
      );

  @override
  @override
  Future<AbsenceCarePlan> getAbsenceCarePlan(String absenceId) async =>
      const AbsenceCarePlan(
        absenceId: 'abs-1',
        today: '2026-09-01',
        startsOn: '2026-10-01',
        endsOn: '2026-10-05',
        pets: [],
      );

  @override
  Future<AwayPlanReadiness> getAwayPlanReadiness(String absenceId) async =>
      const AwayPlanReadiness(
        carerCoverage: CarerCoverageFact(
          state: 'none_have_carers',
          petsWithCarer: 0,
          petsTotal: 1,
          copyKey: 'awayPlanningCarerCoverageNoneHaveCarers',
        ),
        careCoverage: CareCoverageFact(
          policyVersion: '1',
          coverageState: 'nothing_scheduled',
          reasonCodes: [],
          reassuranceAvailable: false,
          copyKey: 'careContextCoverageNothingScheduled',
        ),
        tileCopy: AwayPlanTileCopy(
          source: 'care_coverage',
          copyKey: 'careContextCoverageNothingScheduled',
          copyParams: {},
        ),
      );

  @override
  Future<PlannedAbsence> updateHandoverNote({
    required String absenceId,
    String? handoverNote,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> recordHandoverDownload(String absenceId) async {}

  @override
  Future<PlannedAbsence> cancelPlannedAbsence(String absenceId) async {
    throw UnimplementedError();
  }
}

const absence = PlannedAbsence(
  id: 'abs-1',
  userId: 'user-1',
  startsOn: '2026-10-01',
  endsOn: '2026-10-05',
  provenance: 'user_declared',
  status: 'active',
  petIds: ['pet-1'],
  petCarers: [PlannedAbsencePetCarer(petId: 'pet-1')],
);

const cancelledAbsence = PlannedAbsence(
  id: 'abs-1',
  userId: 'user-1',
  startsOn: '2026-10-01',
  endsOn: '2026-10-05',
  provenance: 'user_declared',
  status: 'cancelled',
  petIds: ['pet-1'],
  petCarers: [PlannedAbsencePetCarer(petId: 'pet-1')],
);

const pet = Pet(id: 'pet-1', name: 'Luna', species: 'dog', breed: 'Mixed');

Widget buildScreen(_FakeCareContextRepository repo, {PlannedAbsence? detail}) {
  return ProviderScope(
    overrides: [
      careContextRepositoryProvider.overrideWith((ref) => repo),
      plannedAbsenceDetailProvider(
        'abs-1',
      ).overrideWith((ref) async => detail ?? absence),
      awayPlanReadinessProvider(
        'abs-1',
      ).overrideWith((ref) async => repo.getAwayPlanReadiness('abs-1')),
      allPetsIncludingOrgProvider.overrideWith((ref) async => [pet]),
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

void main() {
  testWidgets('edit affordance per pet row saves a shared user carer', (
    tester,
  ) async {
    final repo = _FakeCareContextRepository(
      candidates: const [
        CarerCandidate(userId: 'user-2', displayName: 'Sarah M.'),
      ],
    );
    await tester.pumpWidget(buildScreen(repo));
    await tester.pumpAndSettle();

    final editButton = find.byKey(const Key('away_plan_carer_edit_pet-1'));
    expect(editButton, findsOneWidget);

    await tester.tap(editButton);
    await tester.pumpAndSettle();

    expect(find.textContaining("Who's caring for Luna"), findsOneWidget);
    expect(find.text('Sarah M.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('away_plan_carer_candidate_user-2')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('away_plan_carer_edit_save')));
    await tester.pumpAndSettle();

    expect(repo.updateCallCount, 1);
    expect(repo.savedPetCarers.single, {
      'pet_id': 'pet-1',
      'carer_kind': 'shared_user',
      'carer_user_id': 'user-2',
      'pet_note': null,
    });
  });

  testWidgets('pet note field saves independent of carer mode', (tester) async {
    final repo = _FakeCareContextRepository(
      candidates: const [
        CarerCandidate(userId: 'user-2', displayName: 'Sarah M.'),
      ],
    );
    await tester.pumpWidget(buildScreen(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('away_plan_carer_edit_pet-1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('away_plan_carer_candidate_user-2')));
    await tester.enterText(
      find.byKey(const Key('away_plan_carer_pet_note')),
      'Feeds twice daily',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('away_plan_carer_edit_save')));
    await tester.pumpAndSettle();

    expect(repo.savedPetCarers.single, {
      'pet_id': 'pet-1',
      'carer_kind': 'shared_user',
      'carer_user_id': 'user-2',
      'pet_note': 'Feeds twice daily',
    });
  });

  testWidgets('note-only mode requires a name before enabling save', (
    tester,
  ) async {
    final repo = _FakeCareContextRepository(candidates: const []);
    await tester.pumpWidget(buildScreen(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('away_plan_carer_edit_pet-1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('away_plan_carer_mode_note_only')));
    await tester.pumpAndSettle();

    final saveButton = find.byKey(const Key('away_plan_carer_edit_save'));
    final filled = tester.widget<FilledButton>(saveButton);
    expect(filled.onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('away_plan_carer_note_only_name')),
      'Tom',
    );
    await tester.pump();

    final filledEnabled = tester.widget<FilledButton>(saveButton);
    expect(filledEnabled.onPressed, isNotNull);
  });

  testWidgets('clear mode sends carer_kind null', (tester) async {
    final repo = _FakeCareContextRepository(candidates: const []);
    await tester.pumpWidget(
      buildScreen(
        repo,
        detail: const PlannedAbsence(
          id: 'abs-1',
          userId: 'user-1',
          startsOn: '2026-10-01',
          endsOn: '2026-10-05',
          provenance: 'user_declared',
          status: 'active',
          petIds: ['pet-1'],
          petCarers: [
            PlannedAbsencePetCarer(
              petId: 'pet-1',
              carerKind: 'note_only',
              carerName: 'Tom',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('away_plan_carer_edit_pet-1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('away_plan_carer_mode_clear')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('away_plan_carer_edit_save')));
    await tester.pumpAndSettle();

    expect(repo.savedPetCarers.single, {
      'pet_id': 'pet-1',
      'carer_kind': null,
      'pet_note': null,
    });
  });

  testWidgets('403 on save re-fetches candidates and shows forbidden copy', (
    tester,
  ) async {
    final repo = _FakeCareContextRepository(
      candidates: const [
        CarerCandidate(userId: 'user-2', displayName: 'Sarah M.'),
      ],
      updateThrows: () => CareContextApiException(403, 'Forbidden'),
    );
    await tester.pumpWidget(buildScreen(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('away_plan_carer_edit_pet-1')));
    await tester.pumpAndSettle();

    expect(repo.getCarerCandidatesCallCount, 1);

    await tester.tap(find.byKey(const Key('away_plan_carer_candidate_user-2')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('away_plan_carer_edit_save')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('no longer has shared access'), findsOneWidget);
    expect(repo.updateCallCount, 1);
    expect(repo.getCarerCandidatesCallCount, 2);
  });

  testWidgets('cancelled absence disables the edit affordance', (tester) async {
    final repo = _FakeCareContextRepository(candidates: const []);
    await tester.pumpWidget(buildScreen(repo, detail: cancelledAbsence));
    await tester.pumpAndSettle();

    final editButton = tester.widget<IconButton>(
      find.byKey(const Key('away_plan_carer_edit_pet-1')),
    );
    expect(editButton.onPressed, isNull);
  });

  testWidgets('cancelled absence disables the per-pet download affordance', (
    tester,
  ) async {
    final repo = _FakeCareContextRepository(candidates: const []);
    await tester.pumpWidget(buildScreen(repo, detail: cancelledAbsence));
    await tester.pumpAndSettle();

    final downloadButton = tester.widget<IconButton>(
      find.byKey(const Key('away_plan_download_pet_pet-1')),
    );
    expect(downloadButton.onPressed, isNull);
  });

  testWidgets('active absence enables the per-pet download affordance', (
    tester,
  ) async {
    final repo = _FakeCareContextRepository(candidates: const []);
    await tester.pumpWidget(buildScreen(repo));
    await tester.pumpAndSettle();

    final downloadButton = tester.widget<IconButton>(
      find.byKey(const Key('away_plan_download_pet_pet-1')),
    );
    expect(downloadButton.onPressed, isNotNull);
  });
}
