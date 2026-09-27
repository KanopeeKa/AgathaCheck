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
  });

  final String plannedAbsenceId;
  final String startsOn;
  final String endsOn;
  final bool affected;
  final String uiState;
  final String? absenceNote;
  final String? suggestedDecision;
  final String? resolutionDecision;

  bool get needsAttention =>
      affected && (uiState == 'not_reviewed' || uiState == 'needs_review');

  factory HealthEntryAbsenceSlice.fromJson(Map<String, dynamic> json) {
    final resolution = json['resolution'] as Map<String, dynamic>?;
    return HealthEntryAbsenceSlice(
      plannedAbsenceId: json['planned_absence_id'] as String? ?? '',
      startsOn: json['starts_on'] as String? ?? '',
      endsOn: json['ends_on'] as String? ?? '',
      affected: json['affected'] as bool? ?? false,
      uiState: json['ui_state'] as String? ?? 'nothing_due',
      absenceNote: resolution?['absence_note'] as String?,
      suggestedDecision: json['suggested_decision'] as String?,
      resolutionDecision: resolution?['decision'] as String?,
    );
  }
}
