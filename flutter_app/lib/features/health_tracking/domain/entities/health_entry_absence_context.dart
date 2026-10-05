import 'package:pet_profile_app/features/pet_care/pet_care.dart';

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

class HealthEntryAbsenceReviewOccurrence {
  const HealthEntryAbsenceReviewOccurrence({
    required this.occurrenceId,
    required this.scheduledDate,
    this.scheduledTime,
  });

  final String occurrenceId;
  final String scheduledDate;
  final String? scheduledTime;

  factory HealthEntryAbsenceReviewOccurrence.fromJson(
    Map<String, dynamic> json,
  ) {
    return HealthEntryAbsenceReviewOccurrence(
      occurrenceId: json['occurrence_id'] as String? ?? '',
      scheduledDate: json['scheduled_date'] as String? ?? '',
      scheduledTime: json['scheduled_time'] as String?,
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
    this.reviewOccurrence,
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
  final HealthEntryAbsenceReviewOccurrence? reviewOccurrence;
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
    final reviewRaw = json['review_occurrence'] as Map<String, dynamic>?;
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
          ? _plannedCareItemFromJson(plannedRaw)
          : null,
      reviewOccurrence: reviewRaw != null
          ? HealthEntryAbsenceReviewOccurrence.fromJson(reviewRaw)
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

PlannedCareItem _plannedCareItemFromJson(Map<String, dynamic> raw) {
  final kind =
      PlannedCareKind.fromWire(raw['kind'] as String?) ??
      PlannedCareKind.singleOnce;
  final timesOfDay = (raw['times_of_day'] as List<dynamic>? ?? const [])
      .map((value) => value.toString())
      .toList(growable: false);

  return PlannedCareItem(
    kind: kind,
    healthEntryId: raw['health_entry_id'] as String? ?? '',
    name: raw['name'] as String? ?? '',
    type: raw['type'] as String?,
    careFamily: raw['care_family'] as String?,
    frequency: raw['frequency'] as String?,
    frequencyInterval: raw['frequency_interval'] as int? ?? 1,
    timesOfDay: timesOfDay,
    nextDueDate: raw['next_due_date'] as String?,
    certainty: raw['certainty'] as String?,
    reason: raw['reason'] as String?,
    occurrenceId: raw['occurrence_id'] as String?,
    scheduledDate: raw['scheduled_date'] as String?,
    status: raw['status'] as String?,
    firstScheduledDate: raw['first_scheduled_date'] as String?,
    lastScheduledDate: raw['last_scheduled_date'] as String?,
    occurrenceCount: raw['occurrence_count'] as int? ?? 0,
    openOccurrence: _openOccurrenceFromJson(
      raw['open_occurrence'] as Map<String, dynamic>?,
    ),
    inWindow: _inWindowFromJson(raw['in_window'] as Map<String, dynamic>?),
    isPaused: raw['is_paused'] == true,
    scheduleFlexibility: raw['schedule_flexibility'] as String?,
  );
}

PlannedCareOpenOccurrence? _openOccurrenceFromJson(Map<String, dynamic>? raw) {
  if (raw == null) return null;
  final scheduledDate = raw['scheduled_date'] as String?;
  final openStatus = raw['open_status'] as String?;
  if (scheduledDate == null ||
      scheduledDate.isEmpty ||
      openStatus == null ||
      openStatus.isEmpty) {
    return null;
  }
  return PlannedCareOpenOccurrence(
    occurrenceId: raw['occurrence_id'] as String?,
    scheduledDate: scheduledDate,
    scheduledTime: raw['scheduled_time'] as String?,
    openStatus: openStatus,
  );
}

PlannedCareInWindow? _inWindowFromJson(Map<String, dynamic>? raw) {
  if (raw == null) return null;
  final firstDate = raw['first_date'] as String?;
  final lastDate = raw['last_date'] as String?;
  if (firstDate == null ||
      firstDate.isEmpty ||
      lastDate == null ||
      lastDate.isEmpty) {
    return null;
  }
  return PlannedCareInWindow(
    firstDate: firstDate,
    lastDate: lastDate,
    count: raw['count'] as int? ?? 0,
    dateBasis: raw['date_basis'] as String? ?? 'scheduled',
  );
}
