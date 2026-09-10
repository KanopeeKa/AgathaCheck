import '../../domain/entities/planned_absence.dart';

class PlannedAbsenceModel {
  static PlannedAbsence fromJson(Map<String, dynamic> json) {
    final petIdsRaw = json['pet_ids'] as List<dynamic>? ?? const [];
    return PlannedAbsence(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      startsOn: json['starts_on'] as String? ?? '',
      endsOn: json['ends_on'] as String? ?? '',
      provenance: json['provenance'] as String? ?? 'user_declared',
      sourceRef: json['source_ref'] as String?,
      status: json['status'] as String? ?? 'active',
      petIds: petIdsRaw.map((id) => id.toString()).toList(growable: false),
    );
  }

  static CreatePlannedAbsenceResult createResultFromJson(
    Map<String, dynamic> json,
  ) {
    final absenceJson = json['absence'] as Map<String, dynamic>? ?? {};
    final warningsJson = json['overlap_warnings'] as List<dynamic>? ?? const [];
    return CreatePlannedAbsenceResult(
      absence: fromJson(absenceJson),
      overlapWarnings: warningsJson
          .map(
            (raw) => PlannedAbsenceOverlapWarning(
              petId: (raw as Map<String, dynamic>)['pet_id'] as String? ?? '',
              conflictingAbsenceId:
                  raw['conflicting_absence_id'] as String? ?? '',
              conflictingStartsOn:
                  raw['conflicting_starts_on'] as String? ?? '',
              conflictingEndsOn: raw['conflicting_ends_on'] as String? ?? '',
            ),
          )
          .toList(growable: false),
    );
  }
}
