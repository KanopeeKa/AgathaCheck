import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_care/context/data/models/away_plan_readiness_model.dart';

void main() {
  test('parses carer_coverage, care_coverage, and tile_copy', () {
    final readiness = AwayPlanReadinessModel.fromJson({
      'carer_coverage': {
        'state': 'some_have_carers',
        'pets_with_carer': 1,
        'pets_total': 2,
        'copy_key': 'awayPlanningCarerCoverageSomeHaveCarers',
      },
      'care_coverage': {
        'policy_version': '1',
        'coverage_state': 'has_items_to_review',
        'reason_codes': [],
        'reassurance_available': true,
        'copy_key': 'careContextCoverageHasItemsToReview',
        'copy_params': {'count': 3},
      },
      'tile_copy': {
        'source': 'care_coverage',
        'copy_key': 'careContextCoverageHasItemsToReview',
        'copy_params': {'count': 3},
      },
    });

    expect(readiness.carerCoverage.petsWithCarer, 1);
    expect(readiness.carerCoverage.petsTotal, 2);
    expect(readiness.careCoverage.copyCount, 3);
    expect(readiness.tileCopy.source, 'care_coverage');
    expect(readiness.tileCopy.copyParams?['count'], 3);
  });
}
