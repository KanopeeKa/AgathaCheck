import '../domain/entities/away_plan_readiness.dart';
import '../domain/entities/planned_absence.dart';

enum AwayPlanningDashboardTileMode { prompt, stateful }

class AwayPlanningDashboardTileState {
  const AwayPlanningDashboardTileState._({
    required this.mode,
    this.absence,
    this.tileCopy,
  });
  final AwayPlanningDashboardTileMode mode;
  final PlannedAbsence? absence;
  final AwayPlanTileCopy? tileCopy;
  static const prompt = AwayPlanningDashboardTileState._(
    mode: AwayPlanningDashboardTileMode.prompt,
  );
  factory AwayPlanningDashboardTileState.stateful({
    required PlannedAbsence absence,
    required AwayPlanTileCopy tileCopy,
  }) => AwayPlanningDashboardTileState._(
    mode: AwayPlanningDashboardTileMode.stateful,
    absence: absence,
    tileCopy: tileCopy,
  );
}
