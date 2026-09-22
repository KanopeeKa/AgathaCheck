import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/pet_care/context/data/datasources/care_context_remote_datasource.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/away_plan_readiness.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/care_period_coverage.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/carer_candidate.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/planned_absence.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/repositories/care_context_repository.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/providers/care_context_providers.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/screens/planned_absence_edit_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// A fake repository that mutates its in-memory absence on
/// updateHandoverNote/cancelPlannedAbsence, so listPlannedAbsences (and
/// therefore [plannedAbsencesListProvider]) reflects real invalidation
/// behaviour rather than a canned response.
class _FakeCareContextRepository implements CareContextRepository {
  _FakeCareContextRepository({required this.absence});

  PlannedAbsence absence;
  int cancelCallCount = 0;
  int listCallCount = 0;
  int updateHandoverNoteCallCount = 0;
  String? lastSavedNote;
  bool updateThrows = false;
  bool cancelThrows = false;

  @override
  Future<PlannedAbsence> getPlannedAbsence(String absenceId) async => absence;

  @override
  Future<PlannedAbsence> updateHandoverNote({
    required String absenceId,
    String? handoverNote,
  }) async {
    updateHandoverNoteCallCount++;
    if (updateThrows) throw CareContextApiException(500, 'Save failed');
    lastSavedNote = handoverNote;
    absence = PlannedAbsence(
      id: absence.id,
      userId: absence.userId,
      startsOn: absence.startsOn,
      endsOn: absence.endsOn,
      provenance: absence.provenance,
      status: absence.status,
      petIds: absence.petIds,
      petCarers: absence.petCarers,
      handoverNote: handoverNote,
    );
    return absence;
  }

  @override
  Future<PlannedAbsence> cancelPlannedAbsence(String absenceId) async {
    cancelCallCount++;
    if (cancelThrows) throw CareContextApiException(500, 'Cancel failed');
    absence = PlannedAbsence(
      id: absence.id,
      userId: absence.userId,
      startsOn: absence.startsOn,
      endsOn: absence.endsOn,
      provenance: absence.provenance,
      status: 'cancelled',
      petIds: absence.petIds,
      petCarers: absence.petCarers,
      handoverNote: absence.handoverNote,
    );
    return absence;
  }

  @override
  Future<List<PlannedAbsence>> listPlannedAbsences({
    String scope = 'all',
  }) async {
    listCallCount++;
    return absence.isCancelled ? const [] : [absence];
  }

  @override
  Future<CarePeriodCoverageResult> getCarePeriodCoverage({
    required String petId,
    required String startsOn,
    required String endsOn,
  }) {
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
  Future<void> recordHandoverDownload(String absenceId) async {}

  @override
  Future<List<CarerCandidate>> getCarerCandidates(String petId) async => [];

  @override
  Future<PlannedAbsence> updatePetCarers({
    required String absenceId,
    required List<Map<String, dynamic>> petCarers,
  }) {
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
  petCarers: [],
  handoverNote: 'Feed twice a day.',
);

Widget buildScreen(_FakeCareContextRepository repo) {
  return ProviderScope(
    overrides: [careContextRepositoryProvider.overrideWith((ref) => repo)],
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/pc/away',
            name: 'petCarePlannedAbsence',
            builder: (_, __) => Consumer(
              builder: (context, ref, _) {
                final absencesAsync = ref.watch(plannedAbsencesListProvider);
                return Scaffold(
                  body: absencesAsync.when(
                    data: (list) => Text(
                      'hub:${list.length}',
                      key: const Key('hub_marker'),
                    ),
                    loading: () =>
                        const Text('hub:loading', key: Key('hub_marker')),
                    error: (_, __) =>
                        const Text('hub:error', key: Key('hub_marker')),
                  ),
                );
              },
            ),
          ),
          GoRoute(
            path: '/pc/away/:id',
            name: 'petCarePlannedAbsenceDetail',
            builder: (_, state) => Text(
              'plan-${state.pathParameters['id']}',
              key: const Key('plan_screen_marker'),
            ),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'petCarePlannedAbsenceEdit',
                builder: (_, state) => PlannedAbsenceEditScreen(
                  absenceId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
        initialLocation: '/pc/away/abs-1/edit',
      ),
    ),
  );
}

void main() {
  testWidgets('renders the note field pre-filled, Save and Delete actions', (
    tester,
  ) async {
    final repo = _FakeCareContextRepository(absence: absence);
    await tester.pumpWidget(buildScreen(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('away_plan_handover_note')), findsOneWidget);
    expect(find.text('Feed twice a day.'), findsOneWidget);
    expect(find.byKey(const Key('away_plan_edit_save')), findsOneWidget);
    expect(find.byKey(const Key('away_plan_edit_delete')), findsOneWidget);
  });

  testWidgets('Save is disabled until the note is dirty', (tester) async {
    final repo = _FakeCareContextRepository(absence: absence);
    await tester.pumpWidget(buildScreen(repo));
    await tester.pumpAndSettle();

    final saveButton = tester.widget<FilledButton>(
      find.byKey(const Key('away_plan_edit_save')),
    );
    expect(saveButton.onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('away_plan_handover_note')),
      'Feed twice a day, meds at 8am.',
    );
    await tester.pump();

    final saveButtonDirty = tester.widget<FilledButton>(
      find.byKey(const Key('away_plan_edit_save')),
    );
    expect(saveButtonDirty.onPressed, isNotNull);
  });

  testWidgets(
    'saving calls updateHandoverNote and returns to the plan screen',
    (tester) async {
      final repo = _FakeCareContextRepository(absence: absence);
      await tester.pumpWidget(buildScreen(repo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('away_plan_handover_note')),
        'Updated note.',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('away_plan_edit_save')));
      await tester.pumpAndSettle();

      expect(repo.updateHandoverNoteCallCount, 1);
      expect(repo.lastSavedNote, 'Updated note.');
      expect(find.byKey(const Key('plan_screen_marker')), findsOneWidget);
    },
  );

  testWidgets(
    'discard guard fires on unsaved note changes and cancel keeps editing',
    (tester) async {
      final repo = _FakeCareContextRepository(absence: absence);
      await tester.pumpWidget(buildScreen(repo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('away_plan_handover_note')),
        'Unsaved change.',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('away_plan_edit_cancel')));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);

      // Cancel out of the discard dialog: still on the edit screen.
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cancel'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('away_plan_handover_note')), findsOneWidget);

      // Discard: navigates back to the plan screen.
      await tester.tap(find.byKey(const Key('away_plan_edit_cancel')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Discard'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('plan_screen_marker')), findsOneWidget);
    },
  );

  testWidgets(
    'delete confirms, cancels the absence, navigates home, and invalidates the hub list',
    (tester) async {
      final repo = _FakeCareContextRepository(absence: absence);
      await tester.pumpWidget(buildScreen(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('away_plan_edit_delete')));
      await tester.pumpAndSettle();

      expect(find.text('Delete this away plan?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('away_plan_edit_delete_confirm')));
      await tester.pumpAndSettle();

      expect(repo.cancelCallCount, 1);
      expect(repo.absence.isCancelled, isTrue);
      expect(find.byKey(const Key('hub_marker')), findsOneWidget);
      // The absence is cancelled, so the hub list (re-fetched after
      // invalidation) no longer includes it.
      expect(find.text('hub:0'), findsOneWidget);
    },
  );

  testWidgets('delete dialog cancel does not call cancelPlannedAbsence', (
    tester,
  ) async {
    final repo = _FakeCareContextRepository(absence: absence);
    await tester.pumpWidget(buildScreen(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('away_plan_edit_delete')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repo.cancelCallCount, 0);
    expect(find.byKey(const Key('away_plan_handover_note')), findsOneWidget);
  });

  testWidgets('uses the sticky actions bar on phone width', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _FakeCareContextRepository(absence: absence);
    await tester.pumpWidget(buildScreen(repo));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('away_plan_edit_sticky_actions')),
      findsOneWidget,
    );
  });
}
