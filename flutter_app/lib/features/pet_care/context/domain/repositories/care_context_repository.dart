import '../entities/care_period_coverage.dart';
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

  Future<List<PlannedAbsence>> listPlannedAbsences();
}
