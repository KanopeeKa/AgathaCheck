import '../../../../l10n/app_localizations.dart';
import '../domain/entities/away_plan_readiness.dart';
import '../domain/entities/planned_absence_pet_carer.dart';

class AwayPlanCopy {
  const AwayPlanCopy._();

  static String carerCoverageSummary(
    AppLocalizations l,
    CarerCoverageFact fact,
  ) {
    return switch (fact.copyKey) {
      'awayPlanningCarerCoverageAllHaveCarers' =>
        l.awayPlanningCarerCoverageAllHaveCarers,
      'awayPlanningCarerCoverageSomeHaveCarers' =>
        l.awayPlanningCarerCoverageSomeHaveCarers(
          fact.petsWithCarer,
          fact.petsTotal,
        ),
      'awayPlanningCarerCoverageNoneHaveCarers' =>
        l.awayPlanningCarerCoverageNoneHaveCarers,
      _ => l.awayPlanningCarerCoverageNoneHaveCarers,
    };
  }

  static String careCoverageSummary(AppLocalizations l, CareCoverageFact fact) {
    return switch (fact.copyKey) {
      'careContextCoverageNothingScheduled' =>
        l.careContextCoverageNothingScheduled,
      'careContextCoverageAllCompleted' => l.careContextCoverageAllCompleted,
      'careContextCoverageNoUnresolved' => l.careContextCoverageNoUnresolved,
      'careContextCoverageHasItemsToReview' =>
        l.careContextCoverageHasItemsToReview(fact.copyCount ?? 0),
      'careContextCoverageIndeterminate' => l.careContextCoverageIndeterminate,
      _ => l.careContextCoverageIndeterminate,
    };
  }

  static String petCarerLabel(AppLocalizations l, PlannedAbsencePetCarer carer) {
    if (carer.carerRemoved) return l.awayPlanningCarerRemoved;
    if (!carer.hasCarer) return l.awayPlanningCarerUnset;
    return switch (carer.carerKind) {
      'shared_user' => l.awayPlanningCarerSharedAccess(
        carer.carerName ?? l.awayPlanningCarerSharedUserFallback,
      ),
      'note_only' => l.awayPlanningCarerNoteOnly(carer.carerName ?? ''),
      _ => l.awayPlanningCarerUnset,
    };
  }
}
