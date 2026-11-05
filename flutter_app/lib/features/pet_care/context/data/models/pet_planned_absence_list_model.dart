import '../../domain/entities/pet_planned_absence_row.dart';
import '../../domain/entities/planned_absence.dart';
import 'per_pet_away_plan_status_model.dart';
import 'planned_absence_model.dart';

class PetPlannedAbsenceListModel {
  const PetPlannedAbsenceListModel._();

  static PetPlannedAbsenceListResult fromJson(Map<String, dynamic> json) {
    final petId = json['pet_id'] as String? ?? '';
    final today = json['today'] as String? ?? '';
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final items = rawItems
        .map((raw) => _rowFromJson(raw as Map<String, dynamic>))
        .toList(growable: false);
    return PetPlannedAbsenceListResult(
      petId: petId,
      today: today,
      items: items,
    );
  }

  static PetPlannedAbsenceRow _rowFromJson(Map<String, dynamic> json) {
    final absenceId = json['absence_id'] as String? ?? '';
    final petId = json['pet_id'] as String? ?? '';
    final absenceJson = json['absence'] as Map<String, dynamic>? ?? const {};
    final statusJson = json['status'] as Map<String, dynamic>? ?? const {};
    return PetPlannedAbsenceRow(
      absenceId: absenceId,
      petId: petId,
      absence: PlannedAbsenceModel.fromJson(absenceJson),
      status: PerPetAwayPlanStatusModel.fromStatusJson(statusJson),
      reviewCareItemCount: json['review_care_item_count'] as int? ?? 0,
      coverageState: json['coverage_state'] as String? ?? '',
    );
  }

  static AddPetToAbsenceResult addPetResultFromJson(Map<String, dynamic> json) {
    final absenceJson = json['absence'] as Map<String, dynamic>? ?? json;
    final warningsRaw = json['overlap_warnings'] as List<dynamic>? ?? const [];
    return AddPetToAbsenceResult(
      absence: PlannedAbsenceModel.fromJson(absenceJson),
      overlapWarnings: warningsRaw
          .map((raw) {
            final map = raw as Map<String, dynamic>;
            return PlannedAbsenceOverlapWarning(
              petId: map['pet_id'] as String? ?? '',
              conflictingAbsenceId:
                  map['conflicting_absence_id'] as String? ?? '',
              conflictingStartsOn:
                  map['conflicting_starts_on'] as String? ?? '',
              conflictingEndsOn: map['conflicting_ends_on'] as String? ?? '',
            );
          })
          .toList(growable: false),
    );
  }

  static RemovePetFromAbsenceResult removePetResultFromJson(
    Map<String, dynamic> json,
  ) {
    final deleted = json['absence_deleted'] == true;
    final absenceId = json['absence_id'] as String? ?? '';
    final petId = json['pet_id'] as String? ?? '';
    PlannedAbsence? absence;
    if (!deleted) {
      final absenceJson = json['absence'] as Map<String, dynamic>?;
      if (absenceJson != null) {
        absence = PlannedAbsenceModel.fromJson(absenceJson);
      }
    }
    return RemovePetFromAbsenceResult(
      absenceDeleted: deleted,
      absenceId: absenceId,
      petId: petId,
      absence: absence,
    );
  }
}
