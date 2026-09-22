// Widget tests for AwayPlanHeaderSection (D-AWD-001: attention-only coverage
// summary). Matrix: 3 carer-coverage states x 5 care-coverage states, per
// the AWD-1 exit criteria in away-plan-detail-v2-delivery-plan.md.
//
// Rule under test:
// - Carer coverage line renders only when carerCoverage.state is not
//   'all_have_carers'.
// - Care coverage line renders only when careCoverage.coverageState is
//   'has_items_to_review' or 'indeterminate'.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/away_plan_readiness.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/planned_absence.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/away_plan_copy.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/widgets/away_plan_header_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

const _absence = PlannedAbsence(
  id: 'abs-1',
  userId: 'user-1',
  startsOn: '2026-10-01',
  endsOn: '2026-10-05',
  provenance: 'user_declared',
  status: 'active',
  petIds: ['pet-1', 'pet-2'],
);

const _carerCoverageByState = <String, CarerCoverageFact>{
  'all_have_carers': CarerCoverageFact(
    state: 'all_have_carers',
    petsWithCarer: 2,
    petsTotal: 2,
    copyKey: 'awayPlanningCarerCoverageAllHaveCarers',
  ),
  'some_have_carers': CarerCoverageFact(
    state: 'some_have_carers',
    petsWithCarer: 1,
    petsTotal: 2,
    copyKey: 'awayPlanningCarerCoverageSomeHaveCarers',
  ),
  'none_have_carers': CarerCoverageFact(
    state: 'none_have_carers',
    petsWithCarer: 0,
    petsTotal: 2,
    copyKey: 'awayPlanningCarerCoverageNoneHaveCarers',
  ),
};

const _careCoverageByState = <String, CareCoverageFact>{
  'nothing_scheduled': CareCoverageFact(
    policyVersion: '1',
    coverageState: 'nothing_scheduled',
    reasonCodes: <String>[],
    reassuranceAvailable: true,
    copyKey: 'careContextCoverageNothingScheduled',
  ),
  'all_completed': CareCoverageFact(
    policyVersion: '1',
    coverageState: 'all_completed',
    reasonCodes: <String>[],
    reassuranceAvailable: true,
    copyKey: 'careContextCoverageAllCompleted',
  ),
  'no_unresolved_items': CareCoverageFact(
    policyVersion: '1',
    coverageState: 'no_unresolved_items',
    reasonCodes: <String>[],
    reassuranceAvailable: true,
    copyKey: 'careContextCoverageNoUnresolved',
  ),
  'has_items_to_review': CareCoverageFact(
    policyVersion: '1',
    coverageState: 'has_items_to_review',
    reasonCodes: <String>[],
    reassuranceAvailable: true,
    copyKey: 'careContextCoverageHasItemsToReview',
    copyCount: 3,
  ),
  'indeterminate': CareCoverageFact(
    policyVersion: '1',
    coverageState: 'indeterminate',
    reasonCodes: <String>[],
    reassuranceAvailable: false,
    copyKey: 'careContextCoverageIndeterminate',
  ),
};

void main() {
  for (final carerEntry in _carerCoverageByState.entries) {
    for (final careEntry in _careCoverageByState.entries) {
      final carerState = carerEntry.key;
      final careState = careEntry.key;
      final expectCarerVisible = carerState != 'all_have_carers';
      final expectCareVisible =
          careState == 'has_items_to_review' || careState == 'indeterminate';

      testWidgets('carer=$carerState, care=$careState -> '
          'carer line ${expectCarerVisible ? "shown" : "hidden"}, '
          'care line ${expectCareVisible ? "shown" : "hidden"}', (
        tester,
      ) async {
        final readiness = AwayPlanReadiness(
          carerCoverage: carerEntry.value,
          careCoverage: careEntry.value,
          tileCopy: const AwayPlanTileCopy(
            source: 'care_coverage',
            copyKey: 'careContextCoverageHasItemsToReview',
            copyParams: {'count': 3},
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AwayPlanHeaderSection(
              absence: _absence,
              readiness: readiness,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(AwayPlanHeaderSection));
        final l = AppLocalizations.of(context)!;

        final carerTitleFinder = find.text(
          l.careContextAwayPlanCarerCoverageTitle,
        );
        final carerSummaryFinder = find.text(
          AwayPlanCopy.carerCoverageSummary(l, readiness.carerCoverage),
        );
        final careTitleFinder = find.text(
          l.careContextAwayPlanCareCoverageTitle,
        );
        final careSummaryFinder = find.text(
          AwayPlanCopy.careCoverageSummary(l, readiness.careCoverage),
        );

        expect(
          carerTitleFinder,
          expectCarerVisible ? findsOneWidget : findsNothing,
          reason: 'carer coverage title for state=$carerState',
        );
        expect(
          carerSummaryFinder,
          expectCarerVisible ? findsOneWidget : findsNothing,
          reason: 'carer coverage summary for state=$carerState',
        );
        expect(
          careTitleFinder,
          expectCareVisible ? findsOneWidget : findsNothing,
          reason: 'care coverage title for state=$careState',
        );
        expect(
          careSummaryFinder,
          expectCareVisible ? findsOneWidget : findsNothing,
          reason: 'care coverage summary for state=$careState',
        );
      });
    }
  }

  testWidgets('renders neither coverage line when both are fully reassured', (
    tester,
  ) async {
    final readiness = AwayPlanReadiness(
      carerCoverage: _carerCoverageByState['all_have_carers']!,
      careCoverage: _careCoverageByState['nothing_scheduled']!,
      tileCopy: const AwayPlanTileCopy(
        source: 'carer_coverage',
        copyKey: 'awayPlanningTileCarerNone',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AwayPlanHeaderSection(absence: _absence, readiness: readiness),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AwayPlanHeaderSection));
    final l = AppLocalizations.of(context)!;

    expect(find.text(l.careContextAwayPlanCarerCoverageTitle), findsNothing);
    expect(find.text(l.careContextAwayPlanCareCoverageTitle), findsNothing);
    // The date range still renders — this is a conditional-rendering
    // change, not a "hide the whole header" change.
    expect(find.textContaining('2026'), findsOneWidget);
  });

  testWidgets('renders both coverage lines when neither is reassured', (
    tester,
  ) async {
    final readiness = AwayPlanReadiness(
      carerCoverage: _carerCoverageByState['none_have_carers']!,
      careCoverage: _careCoverageByState['indeterminate']!,
      tileCopy: const AwayPlanTileCopy(
        source: 'care_coverage',
        copyKey: 'careContextCoverageIndeterminate',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AwayPlanHeaderSection(absence: _absence, readiness: readiness),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AwayPlanHeaderSection));
    final l = AppLocalizations.of(context)!;

    expect(find.text(l.careContextAwayPlanCarerCoverageTitle), findsOneWidget);
    expect(find.text(l.careContextAwayPlanCareCoverageTitle), findsOneWidget);
  });
}
