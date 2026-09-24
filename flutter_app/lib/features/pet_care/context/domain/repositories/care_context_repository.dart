import '../entities/absence_care_plan.dart';
import '../entities/away_plan_readiness.dart';
import '../entities/care_period_coverage.dart';
import '../entities/carer_candidate.dart';
import '../entities/planned_absence.dart';

abstract class CareContextRepository {
  Future<CarePeriodCoverageResult> getCarePeriodCoverage({
    required String petId,
    required String startsOn,
    required String endsOn,
  });

  Future<CreatePlannedAbsenceResult> createPlannedAbsence({
    required String startsOn,
    required String endsOn,
    required List<String> petIds,
  });

  Future<List<PlannedAbsence>> listPlannedAbsences({String scope = 'all'});

  Future<PlannedAbsence> getPlannedAbsence(String absenceId);

  Future<AwayPlanReadiness> getAwayPlanReadiness(String absenceId);

  Future<AbsenceCarePlan> getAbsenceCarePlan(String absenceId);

  Future<PlannedAbsence> updateHandoverNote({
    required String absenceId,
    String? handoverNote,
  });

  Future<void> recordHandoverDownload(String absenceId);

  Future<List<CarerCandidate>> getCarerCandidates(String petId);

  Future<PlannedAbsence> updatePetCarers({
    required String absenceId,
    required List<Map<String, dynamic>> petCarers,
  });

  /// Cancels (soft-deletes) the whole absence plan via the existing
  /// `POST /api/planned-absences/:id/cancel` endpoint. There is no hard
  /// delete — this is what the edit screen's "Delete" action calls.
  Future<PlannedAbsence> cancelPlannedAbsence(String absenceId);
}
