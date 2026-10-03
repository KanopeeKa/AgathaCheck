import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';

/// Server-backed care items for widget tests: status and "today" come from
/// the schedule, as on a real list read (D-CIE-028).

DateTime careToday() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

CareAsOf careAsOfNow({String time = '09:00'}) =>
    CareAsOf(date: careToday(), time: time, timezone: 'Europe/Paris');

HealthEntry scheduledEntry({
  required String id,
  required String name,
  String petId = 'pet-1',
  int dueInDays = 0,
  String? time,
  CareOccurrenceStatus? status,
  bool fixed = false,
  String careFamily = 'parasite_prevention',
  HealthFrequency frequency = HealthFrequency.monthly,
  String entryStatus = 'active',
  List<OpenOccurrence>? open,
  String asOfTime = '09:00',
}) {
  final today = careToday();
  final due = today.add(Duration(days: dueInDays));
  final occStatus =
      status ??
      (dueInDays < 0
          ? CareOccurrenceStatus.overdue
          : dueInDays == 0
          ? CareOccurrenceStatus.due
          : CareOccurrenceStatus.comingUp);
  final schedule = CareItemSchedule(
    entryId: id,
    petId: petId,
    name: name,
    careFamily: careFamily,
    isFixedSchedule: fixed,
    status: entryStatus,
    openOccurrences:
        open ??
        [
          OpenOccurrence(
            id: '$id-occ',
            date: due,
            time: time,
            status: occStatus,
            origin: fixed
                ? CareOccurrenceOrigin.schedule
                : CareOccurrenceOrigin.computed,
          ),
        ],
    asOf: careAsOfNow(time: asOfTime),
    repeatsDailyOrMore: frequency == HealthFrequency.daily,
    intervalDays: switch (frequency) {
      HealthFrequency.daily => 1,
      HealthFrequency.weekly => 7,
      HealthFrequency.monthly => 30,
      HealthFrequency.yearly => 365,
      _ => null,
    },
  );
  return HealthEntry(
    id: id,
    petId: petId,
    name: name,
    type: HealthEntryType.medication,
    frequency: frequency,
    startDate: today.subtract(const Duration(days: 60)),
    nextDueDate: due,
    status: entryStatus,
    schedule: schedule,
  );
}
