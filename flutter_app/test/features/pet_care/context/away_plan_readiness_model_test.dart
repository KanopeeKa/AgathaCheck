import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_care/context/data/models/away_plan_readiness_model.dart';

void main() {
  test('parses tile_copy from readiness response', () {
    final readiness = AwayPlanReadinessModel.fromJson({
      'tile_copy': {
        'source': 'carer_coverage',
        'copy_key': 'awayPlanningTileCarerNone',
      },
    });

    expect(readiness.tileCopy.source, 'carer_coverage');
    expect(readiness.tileCopy.copyKey, 'awayPlanningTileCarerNone');
  });

  test('parses tile_copy params for care coverage copy', () {
    final readiness = AwayPlanReadinessModel.fromJson({
      'tile_copy': {
        'source': 'care_coverage',
        'copy_key': 'careContextCoverageHasItemsToReview',
        'copy_params': {'count': 3},
      },
    });

    expect(readiness.tileCopy.copyParams?['count'], 3);
  });
}
