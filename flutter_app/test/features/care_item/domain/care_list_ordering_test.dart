import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import '../../../helpers/care_schedule_entries.dart';

void main() {
  test('partitionCareList merges due soon into upcoming', () {
    final dueSoon = scheduledEntry(id: 'soon', name: 'Soon', dueInDays: 3);
    final later = scheduledEntry(id: 'later', name: 'Later', dueInDays: 20);
    final partition = partitionCareList([dueSoon, later], (e) => e.schedule);
    expect(partition.today, isEmpty);
    expect(partition.upcoming.map((e) => e.id), ['soon', 'later']);
  });

  test('partitionCareList keeps today and upcoming separate', () {
    final today = scheduledEntry(id: 'today', name: 'Today', dueInDays: 0);
    final later = scheduledEntry(id: 'later', name: 'Later', dueInDays: 12);
    final partition = partitionCareList([today, later], (e) => e.schedule);
    expect(partition.today.map((e) => e.id), ['today']);
    expect(partition.upcoming.map((e) => e.id), ['later']);
  });

  test('buildCareListTodayContent exposes quiet done lines', () {
    final entry = scheduledEntry(id: 'meds', name: 'meds', dueInDays: 0);
    final schedule = entry.schedule!;
    final patched = CareItemSchedule(
      entryId: schedule.entryId,
      petId: schedule.petId,
      name: schedule.name,
      careFamily: schedule.careFamily,
      isFixedSchedule: schedule.isFixedSchedule,
      status: schedule.status,
      openOccurrences: schedule.openOccurrences,
      asOf: schedule.asOf,
      completionsToday: [
        CompletionToday(
          occurrenceId: 'occ-1',
          scheduledDate: schedule.asOf.date,
          completedOn: schedule.asOf.date,
          time: '08:05',
        ),
      ],
    );
    final content = buildCareListTodayContent(patched);
    expect(content.quietDone, hasLength(1));
    expect(content.openLines, isNotEmpty);
  });
}
