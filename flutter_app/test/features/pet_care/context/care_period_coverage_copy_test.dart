import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/pet_care/context/domain/entities/care_period_coverage.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/care_period_coverage_copy.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

CarePeriodCoverageResult _result({
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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CarePeriodCoverageCopy', () {
    late AppLocalizations l;

    setUpAll(() async {
      l = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('summary maps nothing_scheduled honestly', () {
      final text = CarePeriodCoverageCopy.summary(
        l,
        _result(state: CarePeriodCoverageState.nothingScheduled),
      );
      expect(text, l.careContextCoverageNothingScheduled);
    });

    test('summary maps indeterminate without reassurance wording', () {
      final text = CarePeriodCoverageCopy.summary(
        l,
        _result(
          state: CarePeriodCoverageState.indeterminate,
          partiallyIndeterminate: true,
        ),
      );
      expect(text, l.careContextCoverageIndeterminate);
    });

    test('summary counts pending items for has_items_to_review', () {
      final text = CarePeriodCoverageCopy.summary(
        l,
        _result(
          state: CarePeriodCoverageState.hasItemsToReview,
          items: const [
            CarePeriodProjectionItem(
              healthEntryId: 'e1',
              scheduledDate: '2026-09-12',
              status: 'pending',
              source: 'projected',
              name: 'Monthly tablet',
              type: 'medication',
              careFamily: 'medication',
            ),
            CarePeriodProjectionItem(
              healthEntryId: 'e2',
              scheduledDate: '2026-09-14',
              status: 'completed',
              source: 'materialised',
              name: 'Flea treatment',
              type: 'preventive',
              careFamily: 'parasite_prevention',
            ),
          ],
        ),
      );
      expect(text, l.careContextCoverageHasItemsToReview(1));
    });

    test('indeterminateQualifier only when projection partially indeterminate', () {
      expect(
        CarePeriodCoverageCopy.indeterminateQualifier(
          l,
          _result(
            state: CarePeriodCoverageState.indeterminate,
            partiallyIndeterminate: true,
          ),
        ),
        l.careContextCoverageIndeterminateQualifier,
      );
      expect(
        CarePeriodCoverageCopy.indeterminateQualifier(
          l,
          _result(state: CarePeriodCoverageState.nothingScheduled),
        ),
        isNull,
      );
    });
  });
}
