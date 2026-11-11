import '../../../core/utils/calendar_date.dart';
import '../domain/care_item_schedule.dart';
import '../domain/care_occurrence.dart';
import '../domain/occurrence_detail.dart';
import '../domain/occurrence_neighbor.dart';
import '../domain/weigh_in_skip_reason.dart';

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
    repeatsDailyOrMore: _repeatsDailyOrMore(json),
    intervalDays: _intervalDays(json),
    lastDone: _lastDone(json['last_done']),
    completionsToday: _completionsToday(json['completions_today']),
  );
}

bool _repeatsDailyOrMore(Map<String, dynamic> json) {
  final interval = (json['frequency_interval'] as num?)?.toInt() ?? 1;
  switch (json['frequency']) {
    case 'daily':
      return interval <= 1;
    case 'custom':
      return ((json['frequency_days'] as num?)?.toInt() ?? 0) == 1;
    default:
      return false;
  }
}

int? _intervalDays(Map<String, dynamic> json) {
  final n = (json['frequency_interval'] as num?)?.toInt() ?? 1;
  switch (json['frequency']) {
    case 'daily':
      return n;
    case 'weekly':
      return 7 * n;
    case 'monthly':
      return 30 * n;
    case 'yearly':
      return 365 * n;
    case 'custom':
      return (json['frequency_days'] as num?)?.toInt();
    default:
      return null;
  }
}

LastDone? _lastDone(Object? raw) {
  if (raw is! Map<String, dynamic>) return null;
  final id = raw['occurrence_id'] as String?;
  if (id == null) return null;
  return LastDone(
    occurrenceId: id,
    completedOn: parseCalendarDate(raw['completed_on']),
    time: _time(raw['time']),
  );
}

List<CompletionToday> _completionsToday(Object? raw) {
  if (raw is! List<dynamic>) return const [];
  return raw
      .map((e) {
        if (e is! Map<String, dynamic>) return null;
        final id = e['occurrence_id'] as String?;
        final completedOn = parseCalendarDate(e['completed_on']);
        final scheduledDate = parseCalendarDate(e['scheduled_date']);
        if (id == null || completedOn == null || scheduledDate == null) {
          return null;
        }
        return CompletionToday(
          occurrenceId: id,
          scheduledDate: scheduledDate,
          scheduledTime: _time(e['scheduled_time']),
          completedOn: completedOn,
          time: _time(e['time']),
        );
      })
      .whereType<CompletionToday>()
      .toList();
}

String? _entryDoseLine(Map<String, dynamic> entry) {
  final dosage = entry['dosage'] as String?;
  if (dosage != null && dosage.trim().isNotEmpty) return dosage.trim();
  final blocks = entry['care_blocks'] as Map<String, dynamic>?;
  final pd = blocks?['product_dose'] as Map<String, dynamic>?;
  if (pd == null) return null;
  final amount = (pd['dose_amount'] as String? ?? '').trim();
  final unit = (pd['dose_unit'] as String? ?? '').trim();
  if (amount.isEmpty && unit.isEmpty) return null;
  return [amount, unit].where((s) => s.isNotEmpty).join(' ');
}

String? _entryStrengthFormLine(Map<String, dynamic> entry) {
  final family = entry['care_family'] as String?;
  if (family != 'medication' && family != 'parasite_prevention') {
    return null;
  }
  final blocks = entry['care_blocks'] as Map<String, dynamic>?;
  final pd = blocks?['product_dose'] as Map<String, dynamic>?;
  if (pd == null) return null;
  final strength = (pd['strength'] as String? ?? '').trim();
  final form = (pd['form'] as String? ?? '').trim();
  if (strength.isEmpty && form.isEmpty) return null;
  if (strength.isEmpty) return form;
  if (form.isEmpty) return strength;
  return '$strength · $form';
}

OccurrenceNeighborSummary? _neighborSummary(Object? raw) {
  if (raw is! Map<String, dynamic>) return null;
  final id = raw['id'] as String?;
  final dateRaw = raw['scheduled_date'] as String?;
  if (id == null || dateRaw == null) return null;
  return OccurrenceNeighborSummary(
    id: id,
    scheduledDate: _requiredDate(dateRaw, 'scheduled_date'),
    scheduledTime: _time(raw['scheduled_time']),
    occurrenceStatus: raw['occurrence_status'] as String? ?? 'due',
    completedOn: parseCalendarDate(raw['completed_on']),
    performedByName: raw['performed_by_name'] as String?,
  );
}

CareOccurrenceStatus _occurrenceScreenStatus(Map<String, dynamic> occ) {
  final stored = occ['status'] as String?;
  if (stored == 'not_recorded') return CareOccurrenceStatus.notRecorded;
  if (stored == 'completed') return CareOccurrenceStatus.done;
  if (stored == 'skipped') return CareOccurrenceStatus.skipped;
  final wire = occ['occurrence_status'] as String? ?? occ['outcome'] as String?;
  return careOccurrenceStatusFromApi(wire);
}

/// `GET /api/health-entries/:id/occurrences/:occId`.
OccurrenceDetail occurrenceDetailFromJson(Map<String, dynamic> json) {
  final occ = json['occurrence'] as Map<String, dynamic>;
  final entry = json['entry'] as Map<String, dynamic>;
  final last = json['last_action'] as Map<String, dynamic>?;
  final weight = json['linked_weight'] as Map<String, dynamic>?;
  final skipRaw = json['skip_reason'] as Map<String, dynamic>?;
  final CareItemSchedule? schedule = entry['as_of'] is Map<String, dynamic>
      ? careItemScheduleFromJson(entry)
      : null;
  return OccurrenceDetail(
    occurrence: CareOccurrence(
      id: occ['id'] as String,
      date: _requiredDate(occ['scheduled_date'], 'scheduled_date'),
      time: _time(occ['scheduled_time']),
      status: _occurrenceScreenStatus(occ),
      origin: careOccurrenceOriginFromApi(occ['origin'] as String?),
      isOpen: occ['status'] == 'pending',
      completedOn: parseCalendarDate(occ['completed_on']),
      markedAt: occ['marked_at'] != null
          ? DateTime.tryParse(occ['marked_at'] as String)
          : null,
      markedByName: occ['marked_by_name'] as String?,
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
      doseLine: _entryDoseLine(entry),
      strengthFormLine: _entryStrengthFormLine(entry),
    ),
    schedule: schedule,
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
            date: parseCalendarDate(weight['date']),
          ),
    skipReason: skipRaw == null
        ? null
        : OccurrenceSkipReason(
            code: skipRaw['code'] as String?,
            note: skipRaw['note'] as String?,
          ),
    previousOccurrence: _neighborSummary(json['previous_occurrence']),
    nextOccurrence: _neighborSummary(json['next_occurrence']),
  );
}
