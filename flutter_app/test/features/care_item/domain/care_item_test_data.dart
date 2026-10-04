import 'package:pet_profile_app/features/care_item/care_item.dart';

/// Builders for care item domain tests.

CareAsOf asOf(int day, String time, {int month = 6}) => CareAsOf(
  date: DateTime(2026, month, day),
  time: time,
  timezone: 'Europe/Paris',
);

OpenOccurrence occ(
  String id,
  int day,
  CareOccurrenceStatus status, {
  String? time,
  int month = 6,
  CareOccurrenceOrigin origin = CareOccurrenceOrigin.schedule,
}) => OpenOccurrence(
  id: id,
  date: DateTime(2026, month, day),
  time: time,
  status: status,
  origin: origin,
);

CareItemSchedule schedule(
  List<OpenOccurrence> open, {
  required CareAsOf at,
  bool fixed = true,
  String? family = 'medication',
  String status = 'active',
}) => CareItemSchedule(
  entryId: 'entry-1',
  petId: 'pet-1',
  name: 'Heartworm pill',
  careFamily: family,
  isFixedSchedule: fixed,
  status: status,
  openOccurrences: open,
  asOf: at,
);
