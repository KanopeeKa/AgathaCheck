import '../../../../l10n/app_localizations.dart';
import '../domain/entities/care_period_coverage.dart';

/// Maps server coverage states to calm, per-pet copy (no cross-pet reassurance).
class CarePeriodCoverageCopy {
  const CarePeriodCoverageCopy._();

  static String summary(
    AppLocalizations l,
    CarePeriodCoverageResult result,
  ) {
    return switch (result.coverage.coverageState) {
      CarePeriodCoverageState.nothingScheduled =>
        l.careContextCoverageNothingScheduled,
      CarePeriodCoverageState.allCompleted =>
        l.careContextCoverageAllCompleted,
      CarePeriodCoverageState.noUnresolvedItems =>
        l.careContextCoverageNoUnresolved,
      CarePeriodCoverageState.hasItemsToReview =>
        l.careContextCoverageHasItemsToReview(_pendingCount(result)),
      CarePeriodCoverageState.indeterminate =>
        l.careContextCoverageIndeterminate,
    };
  }

  static String? indeterminateQualifier(
    AppLocalizations l,
    CarePeriodCoverageResult result,
  ) {
    if (!result.isPartiallyIndeterminate) return null;
    return l.careContextCoverageIndeterminateQualifier;
  }

  static int _pendingCount(CarePeriodCoverageResult result) {
    return result.items.where((item) => item.isPending).length;
  }
}
