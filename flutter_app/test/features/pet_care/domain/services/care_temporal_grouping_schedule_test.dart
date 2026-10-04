import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_entry_model.dart';
import 'package:pet_profile_app/features/pet_care/domain/care_temporal_group.dart';
import 'package:pet_profile_app/features/pet_care/domain/services/care_temporal_grouping_service.dart';

/// Server-backed entries take status only from `open_occurrences` and
/// `as_of` (C2: the six old due rules no longer read the device clock).
Map<String, dynamic> entryJson({
  required List<Map<String, dynamic>> open,
  String today = '2026-06-10',
  String time = '10:00',
  String frequency = 'monthly',
  String recurrenceAnchor = 'from_due_date',
  String nextDue = '2020-01-01',
}) => {
  'id': 'entry-1',
  'pet_id': 'pet-1',
  'name': 'Pill',
  'type': 'medication',
  'frequency': frequency,
  'frequency_interval': 1,
  'start_date': '2026-01-01',
  'next_due_date': nextDue,
  'recurrence_anchor': recurrenceAnchor,
  'status': 'active',
  'remind_days_before': 1,
  'open_occurrences': open,
  'as_of': {'date': today, 'time': time, 'timezone': 'Europe/Paris'},
};

Map<String, dynamic> slot(
  String id,
  String date,
  String status, {
  String? time,
}) => {
  'id': id,
  'scheduled_date': date,
  'scheduled_time': time,
  'status': status,
  'origin': 'schedule',
};

void main() {
  const service = CareTemporalGroupingService();
  final deviceNow = DateTime(2031, 1, 1);

  test('the server status wins over next_due_date and the device clock', () {
    final entry = HealthEntryModel.fromJson(
      entryJson(open: [slot('a', '2026-06-10', 'due')]),
    );
    expect(entry.schedule, isNotNull);
    expect(entry.isOverdue, isFalse);
    expect(entry.isDueToday, isTrue);
    expect(service.groupForEntry(entry, deviceNow), CareTemporalGroup.today);
  });

  test('not recorded + due today is a stack and needs attention', () {
    final entry = HealthEntryModel.fromJson(
      entryJson(
        open: [
          slot('y', '2026-06-09', 'not_recorded'),
          slot('t', '2026-06-10', 'due'),
        ],
      ),
    );
    expect(entry.isOverdue, isTrue);
    expect(
      service.groupForEntry(entry, deviceNow),
      CareTemporalGroup.needsAttention,
    );
  });

  test('due soon is upcoming; later dates do not affect Care Status', () {
    final soon = HealthEntryModel.fromJson(
      entryJson(open: [slot('s', '2026-06-15', 'coming_up')]),
    );
    final later = HealthEntryModel.fromJson(
      entryJson(open: [slot('l', '2026-12-01', 'coming_up')]),
    );
    expect(service.groupForEntry(soon, deviceNow), CareTemporalGroup.upcoming);
    expect(service.groupForEntry(later, deviceNow), isNull);
  });

  test('a paused item never groups', () {
    final json = entryJson(open: [slot('a', '2026-06-01', 'overdue')])
      ..['status'] = 'paused';
    expect(
      service.groupForEntry(HealthEntryModel.fromJson(json), deviceNow),
      isNull,
    );
  });
}
