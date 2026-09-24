import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/reschedule_occurrence_result.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_repository.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/absence_care_plan.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/care_period_coverage.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/providers/care_context_providers.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/widgets/away_plan_suggestions_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _PlannerTestHealthRepository implements HealthRepository {
  _PlannerTestHealthRepository(this.entry, {this.onReschedule});

  final HealthEntry entry;
  final Future<RescheduleOccurrenceResult> Function(
    String entryId,
    String occurrenceId,
    DateTime newDate, {
    String? reasonCode,
  })?
  onReschedule;

  @override
  Future<HealthEntry?> getEntry(String id) async => entry;

  @override
  Future<RescheduleOccurrenceResult> rescheduleOccurrence(
    String entryId,
    String occurrenceId,
    DateTime newDate, {
    String? reasonCode,
  }) {
    return onReschedule!(
      entryId,
      occurrenceId,
      newDate,
      reasonCode: reasonCode,
    );
  }

  @override
  Future<HealthOccurrence> undoOccurrence(
    String entryId,
    String occurrenceId,
  ) async => HealthOccurrence(
    id: occurrenceId,
    entryId: entryId,
    scheduledDate: DateTime(2026, 10, 8),
    status: 'pending',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const suggestion = CarePlannerSuggestion(
    healthEntryId: 'entry-1',
    occurrenceId: 'occ-1',
    fromDate: '2026-10-08',
    toDate: '2026-10-05',
    direction: 'earlier',
    inWindowBefore: 1,
    inWindowAfter: 0,
    flexibility: 'flexible',
    rationaleCode: 'move_before_departure',
  );

  AbsenceCarePlan planWithSuggestion({
    List<CarePlannerSuggestion> suggestions = const [suggestion],
  }) {
    return AbsenceCarePlan(
      absenceId: 'abs-1',
      today: '2026-09-20',
      startsOn: '2026-10-01',
      endsOn: '2026-10-05',
      pets: [
        AbsenceCarePlanPet(
          petId: 'pet-1',
          suggestions: suggestions,
          carerTasks: const CarePlannerCarerTasks(count: 2, byEntry: []),
        ),
      ],
    );
  }

  final entry = HealthEntry(
    id: 'entry-1',
    petId: 'pet-1',
    name: 'Grooming',
    type: HealthEntryType.medication,
    frequency: HealthFrequency.monthly,
    startDate: DateTime(2026, 1, 1),
    nextDueDate: DateTime(2026, 10, 8),
  );

  Widget buildWidget({
    required AbsenceCarePlan plan,
    required HealthRepository repository,
  }) {
    return ProviderScope(
      overrides: [
        absenceCarePlanProvider('abs-1').overrideWith((ref) async => plan),
        healthRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AwayPlanSuggestionsSection(
            absenceId: 'abs-1',
            petId: 'pet-1',
            startsOn: '2026-10-01',
            endsOn: '2026-10-05',
            plannedCareItems: const [
              PlannedCareItem(
                kind: PlannedCareKind.recurringChain,
                healthEntryId: 'entry-1',
                name: 'Grooming',
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('hidden when no suggestions and no carer tasks', (tester) async {
    final repository = _PlannerTestHealthRepository(entry);
    final emptyPlan = const AbsenceCarePlan(
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
    );
    await tester.pumpWidget(
      buildWidget(plan: emptyPlan, repository: repository),
    );
    await tester.pumpAndSettle();
    expect(find.text('Suggested by Agatha'), findsNothing);
  });

  testWidgets('shows suggestions and carer task summary', (tester) async {
    final repository = _PlannerTestHealthRepository(entry);
    await tester.pumpWidget(
      buildWidget(plan: planWithSuggestion(), repository: repository),
    );
    await tester.pumpAndSettle();
    expect(find.text('Suggested by Agatha'), findsOneWidget);
    expect(find.text('Grooming'), findsOneWidget);
    expect(find.textContaining('care tasks'), findsOneWidget);
  });

  testWidgets('accept reschedules with away_planner reason', (tester) async {
    String? capturedReason;
    final repository = _PlannerTestHealthRepository(
      entry,
      onReschedule: (entryId, occurrenceId, newDate, {reasonCode}) async {
        capturedReason = reasonCode;
        expect(entryId, 'entry-1');
        expect(occurrenceId, 'occ-1');
        expect(newDate, DateTime(2026, 10, 5));
        return RescheduleOccurrenceResult(
          occurrence: HealthOccurrence(
            id: 'occ-1',
            entryId: 'entry-1',
            scheduledDate: DateTime(2026, 10, 5),
            status: 'pending',
          ),
          warnings: const [],
          nextDueDate: DateTime(2026, 10, 5),
        );
      },
    );

    await tester.pumpWidget(
      buildWidget(plan: planWithSuggestion(), repository: repository),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('planner_accept_entry-1')));
    await tester.pumpAndSettle();

    expect(capturedReason, 'away_planner');
  });

  testWidgets('not now hides suggestion for the session', (tester) async {
    final repository = _PlannerTestHealthRepository(entry);
    await tester.pumpWidget(
      buildWidget(plan: planWithSuggestion(), repository: repository),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('planner_not_now_entry-1')));
    await tester.pumpAndSettle();
    expect(find.text('Move from'), findsNothing);
  });
}
