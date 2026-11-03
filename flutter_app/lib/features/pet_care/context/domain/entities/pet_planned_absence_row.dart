import 'per_pet_away_plan_status.dart';
import 'planned_absence.dart';

/// One upcoming/current away plan row for a pet page section (GET /pets/:id/planned-absences).
class PetPlannedAbsenceRow {
  const PetPlannedAbsenceRow({
    required this.absenceId,
    required this.petId,
    required this.absence,
    required this.status,
    required this.reviewCareItemCount,
    required this.coverageState,
  });

  final String absenceId;
  final String petId;
  final PlannedAbsence absence;
  final PerPetAwayPlanStatus status;
  final int reviewCareItemCount;
  final String coverageState;
}

class PetPlannedAbsenceListResult {
  const PetPlannedAbsenceListResult({
    required this.petId,
    required this.today,
    required this.items,
  });

  final String petId;
  final String today;
  final List<PetPlannedAbsenceRow> items;
}

class AddPetToAbsenceResult {
  const AddPetToAbsenceResult({
    required this.absence,
    required this.overlapWarnings,
  });

  final PlannedAbsence absence;
  final List<PlannedAbsenceOverlapWarning> overlapWarnings;
}

class RemovePetFromAbsenceResult {
  const RemovePetFromAbsenceResult({
    required this.absenceDeleted,
    required this.absenceId,
    required this.petId,
    this.absence,
  });

  final bool absenceDeleted;
  final String absenceId;
  final String petId;
  final PlannedAbsence? absence;
}
