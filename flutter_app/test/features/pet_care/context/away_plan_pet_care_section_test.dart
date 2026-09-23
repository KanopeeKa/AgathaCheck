import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/care_period_coverage.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/providers/care_context_providers.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/widgets/away_plan_pet_care_section.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

CarePeriodCoverageResult _coverage({
  required List<PlannedCareItem> plannedCareItems,
}) {
  return CarePeriodCoverageResult(
    startsOn: '2026-10-01',
    endsOn: '2026-10-05',
    projectionStatus: CarePeriodProjectionStatus.complete,
    items: const [],
    plannedCareItems: plannedCareItems,
    coverage: const CarePeriodCoverageSummary(
      policyVersion: '1',
      coverageState: CarePeriodCoverageState.hasItemsToReview,
      reasonCodes: [],
      reassuranceAvailable: true,
    ),
  );
}

void main() {
  const pet = Pet(id: 'pet-1', name: 'Luna', species: 'dog', breed: 'Mixed');

  Widget buildSection(CarePeriodCoverageResult coverage) {
    return ProviderScope(
      overrides: [
        petByIdProvider('pet-1').overrideWith((ref) async => pet),
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
              path: '/',
              builder: (_, __) => AwayPlanPetCareSection(
                petId: 'pet-1',
                petName: 'Luna',
                startsOn: '2026-10-01',
                endsOn: '2026-10-05',
                onRetry: () {},
              ),
            ),
            GoRoute(
              path: '/pet/:petId',
              name: 'petDetail',
              builder: (_, state) =>
                  Text('pet-detail-${state.pathParameters['petId']}'),
            ),
            GoRoute(
              path: '/pet/:petId/events/:entryId',
              name: 'petEventView',
              builder: (_, state) =>
                  Text('event-${state.pathParameters['entryId']}'),
            ),
          ],
          initialLocation: '/',
        ),
      ),
    );
  }

  testWidgets('renders unified planned care list with chain explainer once', (
    tester,
  ) async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(
      buildSection(
        _coverage(
          plannedCareItems: [
            PlannedCareItem(
              kind: PlannedCareKind.recurringChain,
              healthEntryId: 'chain-1',
              name: 'Booster',
              type: 'medication',
              careFamily: 'medication',
              frequency: 'weekly',
            ),
            PlannedCareItem(
              kind: PlannedCareKind.indeterminatePending,
              healthEntryId: 'pending-1',
              name: 'Follow-up',
              reason: 'from_completion_pending',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l.awayPlanningScheduleDatedTitle), findsOneWidget);
    expect(find.text(l.awayPlanningChainAnchorExplainer), findsOneWidget);
    expect(find.text('Booster'), findsOneWidget);
    expect(find.text('Follow-up'), findsOneWidget);
  });

  testWidgets('carer can read pending single_once due date without tapping', (
    tester,
  ) async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final dueLabel = l.awayPlanningEventSingleCareOn(
      formatCalendarDateDisplay(parseCalendarDate('2026-10-03')!),
    );
    await tester.pumpWidget(
      buildSection(
        _coverage(
          plannedCareItems: [
            PlannedCareItem(
              kind: PlannedCareKind.singleOnce,
              healthEntryId: 'once-1',
              name: 'Vet visit',
              scheduledDate: '2026-10-03',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(dueLabel), findsOneWidget);
  });

  testWidgets(
    'carer can read recurring_calendar next due date without tapping',
    (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      final dueLabel = l.awayPlanningEventNextDueDate(
        formatCalendarDateDisplay(parseCalendarDate('2026-10-02')!),
      );
      await tester.pumpWidget(
        buildSection(
          _coverage(
            plannedCareItems: [
              PlannedCareItem(
                kind: PlannedCareKind.recurringCalendar,
                healthEntryId: 'daily-1',
                name: 'Morning pill',
                frequency: 'daily',
                firstScheduledDate: '2026-10-01',
                lastScheduledDate: '2026-10-04',
                nextDueDate: '2026-10-02',
                timesOfDay: const ['08:00'],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(dueLabel), findsOneWidget);
    },
  );

  testWidgets('planned care row tap navigates to petEventView with returnTo', (
    tester,
  ) async {
    late GoRouter router;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          petByIdProvider('pet-1').overrideWith((ref) async => pet),
          carePeriodCoverageProvider((
            petId: 'pet-1',
            startsOn: '2026-10-01',
            endsOn: '2026-10-05',
          )).overrideWith((ref) async => _coverage(
                plannedCareItems: [
                  PlannedCareItem(
                    kind: PlannedCareKind.singleOnce,
                    healthEntryId: 'once-1',
                    name: 'Vet visit',
                    scheduledDate: '2026-10-03',
                  ),
                ],
              )),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router = GoRouter(
            routes: [
              GoRoute(
                path: '/pc/away/abs-1',
                builder: (_, __) => AwayPlanPetCareSection(
                  petId: 'pet-1',
                  petName: 'Luna',
                  startsOn: '2026-10-01',
                  endsOn: '2026-10-05',
                  onRetry: () {},
                ),
              ),
              GoRoute(
                path: '/pet/:petId',
                name: 'petDetail',
                builder: (_, state) =>
                    Text('pet-detail-${state.pathParameters['petId']}'),
              ),
              GoRoute(
                path: '/pet/:petId/events/:entryId',
                name: 'petEventView',
                builder: (_, state) =>
                    Text('event-${state.pathParameters['entryId']}'),
              ),
            ],
            initialLocation: '/pc/away/abs-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vet visit'));
    await tester.pumpAndSettle();

    expect(find.text('event-once-1'), findsOneWidget);
    final uri = router.routerDelegate.currentConfiguration.uri;
    expect(uri.path, '/pet/pet-1/events/once-1');
    expect(
      uri.queryParameters['returnTo'],
      Uri.decodeComponent(Uri.encodeComponent('/pc/away/abs-1')),
    );
  });

  testWidgets('pet header tap navigates to petDetail', (tester) async {
    await tester.pumpWidget(
      buildSection(_coverage(plannedCareItems: const [])),
    );
    await tester.pumpAndSettle();

    final semantics = tester.getSemantics(
      find.bySemanticsIdentifier('away_plan_pet_header_pet-1'),
    );
    expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);

    await tester.tap(find.text('Luna').first);
    await tester.pumpAndSettle();

    expect(find.text('pet-detail-pet-1'), findsOneWidget);
  });
}
