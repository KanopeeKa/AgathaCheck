import '../../domain/entities/planned_absence.dart';
import '../../domain/entities/planned_absence_pet_carer.dart';

class PlannedAbsenceModel {
  static PlannedAbsencePetCarer petCarerFromJson(Map<String, dynamic> json) {
    return PlannedAbsencePetCarer(
      petId: json['pet_id'] as String? ?? '',
      carerKind: json['carer_kind'] as String?,
      carerUserId: json['carer_user_id'] as String?,
      carerName: json['carer_name'] as String?,
      carerNote: json['carer_note'] as String?,
      carerRemoved: json['carer_removed'] == true,
      petNote: json['pet_note'] as String?,
    );
  }

  static PlannedAbsence fromJson(Map<String, dynamic> json) {
    final petCarersRaw = json['pet_carers'] as List<dynamic>? ?? const [];
    final petCarers = petCarersRaw
        .map((raw) => petCarerFromJson(raw as Map<String, dynamic>))
        .toList(growable: false);
    final petIdsRaw = json['pet_ids'] as List<dynamic>? ?? const [];
    final petIds = petIdsRaw.isNotEmpty
        ? petIdsRaw.map((id) => id.toString()).toList(growable: false)
        : petCarers.map((carer) => carer.petId).toList(growable: false);

    return PlannedAbsence(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      startsOn: json['starts_on'] as String? ?? '',
      endsOn: json['ends_on'] as String? ?? '',
      provenance: json['provenance'] as String? ?? 'user_declared',
      sourceRef: json['source_ref'] as String?,
      status: json['status'] as String? ?? 'active',
      petIds: petIds,
      petCarers: petCarers,
      handoverNote: json['handover_note'] as String?,
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
