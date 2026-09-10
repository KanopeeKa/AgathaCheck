import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/pet_care/context/domain/entities/care_period_coverage.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/widgets/care_period_pet_preview_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

CarePeriodCoverageResult _sampleResult({
  required CarePeriodCoverageState state,
  bool partiallyIndeterminate = false,
  List<CarePeriodProjectionItem> items = const [],
}) {
  return CarePeriodCoverageResult(
    startsOn: '2026-09-10',
    endsOn: '2026-09-17',
    projectionStatus: partiallyIndeterminate
        ? CarePeriodProjectionStatus.partiallyIndeterminate
        : CarePeriodProjectionStatus.complete,
    uncertainties: const [],
    items: items,
    coverage: CarePeriodCoverageSummary(
      policyVersion: '1',
      coverageState: state,
      reasonCodes: const [],
      reassuranceAvailable: state != CarePeriodCoverageState.indeterminate,
    ),
  );
}

void main() {
  testWidgets('shows per-pet indeterminate copy without global reassurance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CarePeriodPetPreviewSection(
          petName: 'Agatha',
          result: _sampleResult(
            state: CarePeriodCoverageState.indeterminate,
            partiallyIndeterminate: true,
            items: const [
              CarePeriodProjectionItem(
                healthEntryId: 'e1',
                scheduledDate: '2026-09-12',
                status: 'pending',
                source: 'materialised',
                name: 'Daily tablet',
                type: 'medication',
                careFamily: 'medication',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(CarePeriodPetPreviewSection));
    final l = AppLocalizations.of(context)!;

    expect(find.text('Agatha'), findsOneWidget);
    expect(find.text(l.careContextCoverageIndeterminate), findsOneWidget);
    expect(find.text(l.careContextCoverageIndeterminateQualifier), findsOneWidget);
    expect(find.text('Daily tablet'), findsOneWidget);
    expect(find.textContaining('All clear'), findsNothing);
    expect(find.textContaining('All covered'), findsNothing);
  });

  testWidgets('shows nothing_scheduled per pet when complete and zero items', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CarePeriodPetPreviewSection(
          petName: 'Milo',
          result: _sampleResult(state: CarePeriodCoverageState.nothingScheduled),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(CarePeriodPetPreviewSection));
    final l = AppLocalizations.of(context)!;

    expect(find.text('Milo'), findsOneWidget);
    expect(find.text(l.careContextCoverageNothingScheduled), findsOneWidget);
  });
}
