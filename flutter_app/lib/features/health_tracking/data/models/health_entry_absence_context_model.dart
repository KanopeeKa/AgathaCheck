import '../../../pet_care/context/data/models/care_period_coverage_model.dart';
import '../../../pet_care/context/domain/entities/care_period_coverage.dart';

class HealthEntryAbsenceContext {
  const HealthEntryAbsenceContext({
    required this.healthEntryId,
    required this.petId,
    required this.absences,
  });

  final String healthEntryId;
  final String petId;
  final List<HealthEntryAbsenceSlice> absences;

  factory HealthEntryAbsenceContext.fromJson(Map<String, dynamic> json) {
    final raw = json['absences'] as List<dynamic>? ?? const [];
    return HealthEntryAbsenceContext(
      healthEntryId: json['health_entry_id'] as String? ?? '',
      petId: json['pet_id'] as String? ?? '',
      absences: raw
          .map(
            (e) => HealthEntryAbsenceSlice.fromJson(e as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }
}

class HealthEntryAbsenceLookedAfterBy {
  const HealthEntryAbsenceLookedAfterBy({
    required this.carerKind,
    this.carerUserId,
    this.carerName,
  });

  final String carerKind;
  final String? carerUserId;
  final String? carerName;

  String? displayName() {
    if (carerName != null && carerName!.trim().isNotEmpty) {
      return carerName!.trim();
    }
    return null;
  }

  Map<String, dynamic> toApiPayload() {
    return {
      'carer_kind': carerKind,
      if (carerUserId != null) 'carer_user_id': carerUserId,
      if (carerName != null) 'carer_name': carerName,
    };
  }

  factory HealthEntryAbsenceLookedAfterBy.fromJson(Map<String, dynamic> json) {
    return HealthEntryAbsenceLookedAfterBy(
      carerKind: json['carer_kind'] as String? ?? '',
      carerUserId: json['carer_user_id'] as String?,
      carerName: json['carer_name'] as String?,
    );
  }
}

class HealthEntryAbsenceSlice {
  const HealthEntryAbsenceSlice({
    required this.plannedAbsenceId,
    required this.startsOn,
    required this.endsOn,
    required this.affected,
    required this.uiState,
    this.absenceNote,
    this.suggestedDecision,
    this.resolutionDecision,
    this.plannedCare,
    this.suggestedLookedAfterBy,
    this.petCarer,
  });

  final String plannedAbsenceId;
  final String startsOn;
  final String endsOn;
  final bool affected;
  final String uiState;
  final String? absenceNote;
  final String? suggestedDecision;
  final String? resolutionDecision;
  final PlannedCareItem? plannedCare;
  final HealthEntryAbsenceLookedAfterBy? suggestedLookedAfterBy;
  final HealthEntryAbsenceLookedAfterBy? petCarer;

  bool get needsAttention =>
      affected && (uiState == 'not_reviewed' || uiState == 'needs_review');

  String? carerDisplayName() {
    return petCarer?.displayName() ?? suggestedLookedAfterBy?.displayName();
  }

  factory HealthEntryAbsenceSlice.fromJson(Map<String, dynamic> json) {
    final resolution = json['resolution'] as Map<String, dynamic>?;
    final plannedRaw = json['planned_care'] as Map<String, dynamic>?;
    final suggestedRaw =
        json['suggested_looked_after_by'] as Map<String, dynamic>?;
    final petCarerRaw = json['pet_carer'] as Map<String, dynamic>?;

    return HealthEntryAbsenceSlice(
      plannedAbsenceId: json['planned_absence_id'] as String? ?? '',
      startsOn: json['starts_on'] as String? ?? '',
      endsOn: json['ends_on'] as String? ?? '',
      affected: json['affected'] as bool? ?? false,
      uiState: json['ui_state'] as String? ?? 'nothing_due',
      absenceNote: resolution?['absence_note'] as String?,
      suggestedDecision: json['suggested_decision'] as String?,
      resolutionDecision: resolution?['decision'] as String?,
      plannedCare: plannedRaw != null
          ? CarePeriodCoverageModel.plannedCareItemFromJson(plannedRaw)
          : null,
      suggestedLookedAfterBy: suggestedRaw != null
          ? HealthEntryAbsenceLookedAfterBy.fromJson(suggestedRaw)
          : null,
      petCarer: petCarerRaw != null
          ? HealthEntryAbsenceLookedAfterBy.fromJson(petCarerRaw)
          : null,
    );
  }
}
