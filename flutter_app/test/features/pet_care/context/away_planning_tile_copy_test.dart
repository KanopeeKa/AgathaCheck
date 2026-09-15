import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/away_plan_readiness.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/away_planning_tile_copy.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('resolves carer-none copy key', () {
    expect(
      AwayPlanningTileCopy.resolve(
        l10n,
        const AwayPlanTileCopy(
          source: 'carer_coverage',
          copyKey: 'awayPlanningTileCarerNone',
        ),
      ),
      l10n.awayPlanningTileCarerNone,
    );
  });

  test('resolves care coverage count copy key', () {
    expect(
      AwayPlanningTileCopy.resolve(
        l10n,
        const AwayPlanTileCopy(
          source: 'care_coverage',
          copyKey: 'careContextCoverageHasItemsToReview',
          copyParams: {'count': 2},
        ),
      ),
      l10n.careContextCoverageHasItemsToReview(2),
    );
  });
}
