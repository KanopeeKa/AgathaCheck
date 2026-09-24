import '../../domain/entities/absence_care_plan.dart';

class AbsenceCarePlanModel {
  static AbsenceCarePlan fromJson(Map<String, dynamic> json) {
    final petsJson = json['pets'] as List<dynamic>? ?? const [];
    return AbsenceCarePlan(
      absenceId: json['absence_id'] as String? ?? '',
      today: json['today'] as String? ?? '',
      startsOn: json['starts_on'] as String? ?? '',
      endsOn: json['ends_on'] as String? ?? '',
      pets: petsJson
          .map((raw) => _petFromJson(raw as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  static AbsenceCarePlanPet _petFromJson(Map<String, dynamic> json) {
    final suggestionsJson = json['suggestions'] as List<dynamic>? ?? const [];
    final carerJson = json['carer_tasks'] as Map<String, dynamic>? ?? const {};
    final byEntryJson = carerJson['by_entry'] as List<dynamic>? ?? const [];
    return AbsenceCarePlanPet(
      petId: json['pet_id'] as String? ?? '',
      suggestions: suggestionsJson
          .map((raw) => _suggestionFromJson(raw as Map<String, dynamic>))
          .toList(growable: false),
      carerTasks: CarePlannerCarerTasks(
        count: (carerJson['count'] as num?)?.toInt() ?? 0,
        byEntry: byEntryJson
            .map((raw) => _carerEntryFromJson(raw as Map<String, dynamic>))
            .toList(growable: false),
      ),
    );
  }

  static CarePlannerSuggestion _suggestionFromJson(Map<String, dynamic> json) {
    return CarePlannerSuggestion(
      healthEntryId: json['health_entry_id'] as String? ?? '',
      occurrenceId: json['occurrence_id'] as String? ?? '',
      fromDate: json['from_date'] as String? ?? '',
      toDate: json['to_date'] as String? ?? '',
      direction: json['direction'] as String? ?? '',
      inWindowBefore: (json['in_window_before'] as num?)?.toInt() ?? 0,
      inWindowAfter: (json['in_window_after'] as num?)?.toInt() ?? 0,
      flexibility: json['flexibility'] as String? ?? '',
      rationaleCode: json['rationale_code'] as String? ?? '',
    );
  }

  static CarePlannerCarerTaskEntry _carerEntryFromJson(
    Map<String, dynamic> json,
  ) {
    return CarePlannerCarerTaskEntry(
      healthEntryId: json['health_entry_id'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String? ?? '',
    );
  }
}
