import '../../../core/utils/calendar_date.dart';
import '../domain/care_item_schedule.dart';
import '../domain/care_occurrence.dart';
import '../domain/occurrence_detail.dart';

/// Parsers for care item wire shapes (`api-reference.md` § Occurrence APIs).

DateTime _requiredDate(Object? raw, String field) {
  final date = parseCalendarDate(raw);
  if (date == null) throw FormatException('care item wire: missing $field');
  return date;
}

String? _time(Object? raw) {
  if (raw == null) return null;
  final s = raw.toString();
  return s.length >= 5 ? s.substring(0, 5) : null;
}

CareAsOf careAsOfFromJson(Map<String, dynamic> json) {
  return CareAsOf(
    date: _requiredDate(json['date'], 'as_of.date'),
    time: _time(json['time']) ?? '00:00',
    timezone: json['timezone'] as String? ?? 'UTC',
  );
}

OpenOccurrence openOccurrenceFromJson(Map<String, dynamic> json) {
  return OpenOccurrence(
    id: json['id'] as String,
    date: _requiredDate(json['scheduled_date'], 'scheduled_date'),
    time: _time(json['scheduled_time']),
    status: careOccurrenceStatusFromApi(json['status'] as String?),
    origin: careOccurrenceOriginFromApi(json['origin'] as String?),
  );
}

/// A care item read (`GET /api/health-entries[/:id]`, or `entry` in a command
/// response).
CareItemSchedule careItemScheduleFromJson(Map<String, dynamic> json) {
  final open = (json['open_occurrences'] as List<dynamic>? ?? const [])
      .map((e) => openOccurrenceFromJson(e as Map<String, dynamic>))
      .toList();
  final estimated = json['estimated_next'] as Map<String, dynamic>?;
  final estimatedDate = parseCalendarDate(estimated?['date']);
  return CareItemSchedule(
    entryId: json['id'] as String,
    petId: json['pet_id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    careFamily: json['care_family'] as String?,
    isFixedSchedule: json['recurrence_anchor'] == 'from_due_date',
    status: json['status'] as String? ?? 'active',
    openOccurrences: open,
    asOf: careAsOfFromJson(json['as_of'] as Map<String, dynamic>),
    estimatedNext: estimatedDate == null
        ? null
        : EstimatedNext(
            date: estimatedDate,
            basis: estimated?['basis'] as String? ?? 'done_today',
          ),
    lateCompletionChoice: json['late_completion_choice'] as String?,
    pausedUntil: parseCalendarDate(json['paused_until']),
    resumeDefaultDate: parseCalendarDate(json['resume_default_date']),
  );
}

/// `GET /api/health-entries/:id/occurrences/:occId`.
OccurrenceDetail occurrenceDetailFromJson(Map<String, dynamic> json) {
  final occ = json['occurrence'] as Map<String, dynamic>;
  final entry = json['entry'] as Map<String, dynamic>;
  final last = json['last_action'] as Map<String, dynamic>?;
  final weight = json['linked_weight'] as Map<String, dynamic>?;
  return OccurrenceDetail(
    occurrence: CareOccurrence(
      id: occ['id'] as String,
      date: _requiredDate(occ['scheduled_date'], 'scheduled_date'),
      time: _time(occ['scheduled_time']),
      status: careOccurrenceStatusFromApi(occ['occurrence_status'] as String?),
      origin: careOccurrenceOriginFromApi(occ['origin'] as String?),
      isOpen: occ['status'] == 'pending',
      completedOn: parseCalendarDate(occ['completed_on']),
      notes: occ['notes'] as String? ?? '',
    ),
    item: CareItemSummary(
      id: entry['id'] as String,
      petId: entry['pet_id'] as String? ?? '',
      name: entry['name'] as String? ?? '',
      careFamily: entry['care_family'] as String?,
      isFixedSchedule: entry['recurrence_anchor'] == 'from_due_date',
      status: entry['status'] as String? ?? 'active',
      lateCompletionChoice: entry['late_completion_choice'] as String?,
      asOf: careAsOfFromJson(entry['as_of'] as Map<String, dynamic>),
    ),
    lastAction: last == null
        ? null
        : CareLastAction(
            type: last['type'] as String,
            occurrenceId: last['occurrence_id'] as String?,
          ),
    linkedWeight: weight == null
        ? null
        : LinkedWeight(
            value: (weight['value'] as num).toDouble(),
            unit: weight['unit'] as String? ?? 'kg',
          ),
  );
}
