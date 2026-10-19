import '../../../../l10n/app_localizations.dart';
import '../domain/entities/care_period_coverage.dart';

/// Maps server coverage states to calm, per-pet copy (no cross-pet reassurance).
class CarePeriodCoverageCopy {
  const CarePeriodCoverageCopy._();

  static String summary(AppLocalizations l, CarePeriodCoverageResult result) {
    return switch (result.coverage.coverageState) {
      CarePeriodCoverageState.nothingScheduled =>
        l.careContextCoverageNothingScheduled,
      CarePeriodCoverageState.allCompleted => l.careContextCoverageAllCompleted,
      CarePeriodCoverageState.noUnresolvedItems =>
        l.careContextCoverageNoUnresolved,
      CarePeriodCoverageState.hasItemsToReview => _hasItemsToReviewCopy(
        l,
        result,
      ),
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

  static String _hasItemsToReviewCopy(
    AppLocalizations l,
    CarePeriodCoverageResult result,
  ) {
    final count = _pendingCount(result);
    if (result.reviewQueue.isNotEmpty ||
        result.coverage.reviewCareItemCount != null) {
      return l.careContextCoverageHasCareItemsToReview(count);
    }
    return l.careContextCoverageHasItemsToReview(count);
  }

  static int _pendingCount(CarePeriodCoverageResult result) {
    final fromCoverage = result.coverage.reviewCareItemCount;
    if (fromCoverage != null) {
      return fromCoverage;
    }
    if (result.reviewQueue.isNotEmpty) {
      return result.reviewQueue.length;
    }
    return result.items.where((item) => item.isPending).length;
  }
}
