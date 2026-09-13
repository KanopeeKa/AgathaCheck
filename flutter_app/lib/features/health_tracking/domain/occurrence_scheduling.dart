import '../../../pet_care/domain/care_temporal_group.dart';
import '../../../pet_care/domain/services/care_temporal_grouping_service.dart';
import 'entities/health_occurrence.dart';
import 'occurrence_missed.dart';

export 'occurrence_missed.dart' show isOccurrenceMissed;

enum OccurrenceZone { missed, dueToday, comingUp }

const _grouping = CareTemporalGroupingService();

OccurrenceZone occurrenceZone(HealthOccurrence occ, DateTime now) {
  final group = _grouping.groupForOccurrence(occ, now);
  return switch (group) {
    CareTemporalGroup.needsAttention => OccurrenceZone.missed,
    CareTemporalGroup.today => OccurrenceZone.dueToday,
    CareTemporalGroup.upcoming => OccurrenceZone.comingUp,
    null => OccurrenceZone.comingUp,
  };
}

int compareOccurrencesForZone(
  HealthOccurrence a,
  HealthOccurrence b,
  OccurrenceZone zone,
) {
  final dateCmp = a.scheduledDate.compareTo(b.scheduledDate);
  final timeA = a.scheduledTime ?? '00:00';
  final timeB = b.scheduledTime ?? '00:00';
  final timeCmp = timeA.compareTo(timeB);
  final asc = dateCmp != 0 ? dateCmp : timeCmp;
  if (zone == OccurrenceZone.missed) {
    return -asc;
  }
  return asc;
}

List<HealthOccurrence> sortOccurrencesByZone(
  List<HealthOccurrence> items,
  OccurrenceZone zone,
) {
  final copy = List<HealthOccurrence>.from(items);
  copy.sort((a, b) => compareOccurrencesForZone(a, b, zone));
  return copy;
}

/// Summary for list-row headlines (one series).
class OccurrenceSummary {
  const OccurrenceSummary({
    required this.openCount,
    required this.missedCount,
    this.missedHead,
    this.nextHead,
  });

  final int openCount;
  final int missedCount;
  final HealthOccurrence? missedHead;
  final HealthOccurrence? nextHead;
}

OccurrenceSummary summarizeOpenOccurrences(
  List<HealthOccurrence> open,
  DateTime now,
) {
  final withMissed = open
      .map((o) => o.copyWithMissed(isOccurrenceMissed(o, now)))
      .toList();
  final missed = withMissed.where((o) => o.missed).toList();
  final missedSorted = sortOccurrencesByZone(missed, OccurrenceZone.missed);
  final nonMissed = withMissed.where((o) => !o.missed).toList();
  HealthOccurrence? nextHead;
  for (final zone in [OccurrenceZone.dueToday, OccurrenceZone.comingUp]) {
    final bucket = nonMissed
        .where((o) => occurrenceZone(o, now) == zone)
        .toList();
    if (bucket.isEmpty) continue;
    nextHead = sortOccurrencesByZone(bucket, zone).first;
    break;
  }
  return OccurrenceSummary(
    openCount: open.length,
    missedCount: missed.length,
    missedHead: missedSorted.isEmpty ? null : missedSorted.first,
    nextHead: nextHead,
  );
}

extension _HealthOccurrenceMissed on HealthOccurrence {
  HealthOccurrence copyWithMissed(bool missed) {
    return HealthOccurrence(
      id: id,
      entryId: entryId,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      status: status,
      completedOn: completedOn,
      markedAt: markedAt,
      markedByUserId: markedByUserId,
      markedByName: markedByName,
      notes: notes,
      missed: missed,
    );
  }
}
