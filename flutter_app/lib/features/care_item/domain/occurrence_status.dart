/// Live status between server reads (D-CIE-028).
///
/// The server's status is authoritative at `as_of`. While care stays on
/// screen the app may only turn a timed Due into Overdue as minutes pass; a
/// new day, resume, or a 15-minute tick asks the server again.
library;

import 'care_occurrence.dart';

/// The server clock advanced by [elapsed], kept on the same day (the caller
/// refetches when the day changes).
CareAsOf liveAsOf(CareAsOf server, Duration elapsed) {
  if (elapsed <= Duration.zero) return server;
  final minutes = (server.minutes + elapsed.inMinutes).clamp(0, 23 * 60 + 59);
  final hh = (minutes ~/ 60).toString().padLeft(2, '0');
  final mm = (minutes % 60).toString().padLeft(2, '0');
  return CareAsOf(
    date: server.date,
    time: '$hh:$mm',
    timezone: server.timezone,
  );
}

/// [occurrence]'s status at [now] (a [liveAsOf] of the read it came from).
CareOccurrenceStatus liveStatus(OpenOccurrence occurrence, CareAsOf now) {
  if (occurrence.status != CareOccurrenceStatus.due) return occurrence.status;
  final at = clockMinutes(occurrence.time);
  if (at != null && occurrence.date == now.date && now.minutes > at) {
    return CareOccurrenceStatus.overdue;
  }
  return occurrence.status;
}

/// Needs attention now: overdue or not recorded.
bool isPastDue(CareOccurrenceStatus status) =>
    status == CareOccurrenceStatus.overdue ||
    status == CareOccurrenceStatus.notRecorded;
