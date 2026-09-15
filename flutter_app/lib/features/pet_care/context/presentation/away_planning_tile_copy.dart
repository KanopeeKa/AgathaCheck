import '../../../../l10n/app_localizations.dart';
import '../domain/entities/away_plan_readiness.dart';

class AwayPlanningTileCopy {
  const AwayPlanningTileCopy._();
  static String resolve(AppLocalizations l, AwayPlanTileCopy c) =>
      switch (c.copyKey) {
        'awayPlanningTileCarerNone' => l.awayPlanningTileCarerNone,
        'awayPlanningTileCarerSome' => l.awayPlanningTileCarerSome,
        'careContextCoverageNothingScheduled' =>
          l.careContextCoverageNothingScheduled,
        'careContextCoverageAllCompleted' => l.careContextCoverageAllCompleted,
        'careContextCoverageNoUnresolved' => l.careContextCoverageNoUnresolved,
        'careContextCoverageHasItemsToReview' =>
          l.careContextCoverageHasItemsToReview(c.copyParams?['count'] ?? 0),
        'careContextCoverageIndeterminate' =>
          l.careContextCoverageIndeterminate,
        _ => l.careContextAwayEntryBody,
      };
}
