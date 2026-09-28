import '../../../../core/utils/calendar_date.dart';
import '../../data/datasources/health_absence_context_remote.dart';
import '../../data/models/health_entry_absence_context_model.dart';

/// Infers absence resolution decision after reschedule from absence review.
String? inferResolutionDecisionAfterReschedule({
  required String newScheduledDate,
  required String absenceStartsOn,
  required String absenceEndsOn,
}) {
  if (newScheduledDate.compareTo(absenceStartsOn) < 0) {
    return 'move_before';
  }
  if (newScheduledDate.compareTo(absenceEndsOn) > 0) {
    return 'move_after';
  }
  return null;
}

Future<void> syncAbsenceResolution({
  required HealthAbsenceContextRemote remote,
  required HealthEntryAbsenceSlice slice,
  required String healthEntryId,
  required String decision,
}) async {
  final lookedAfter = slice.suggestedLookedAfterBy?.toApiPayload();
  await remote.saveResolution(
    absenceId: slice.plannedAbsenceId,
    healthEntryId: healthEntryId,
    decision: decision,
    lookedAfterBy: lookedAfter,
  );
}

/// Whether [wireDate] falls inside the absence window (inclusive).
bool occurrenceDateIntersectsAbsence({
  required String wireDate,
  required String startsOn,
  required String endsOn,
}) {
  return wireDate.compareTo(startsOn) >= 0 && wireDate.compareTo(endsOn) <= 0;
}

/// Primary conflict date for copy: open head, else next due, else in-window first date.
String? primaryAbsenceConflictDate(HealthEntryAbsenceSlice slice) {
  final planned = slice.plannedCare;
  if (planned == null) return null;
  final openDate = planned.openOccurrence?.scheduledDate;
  if (openDate != null && openDate.isNotEmpty) return openDate;
  if (planned.nextDueDate != null && planned.nextDueDate!.isNotEmpty) {
    return planned.nextDueDate;
  }
  return planned.inWindow?.firstDate;
}

bool absenceSliceConflictsOnDate(
  HealthEntryAbsenceSlice slice,
  String wireDate,
) {
  if (!slice.affected) return false;
  return occurrenceDateIntersectsAbsence(
    wireDate: wireDate,
    startsOn: slice.startsOn,
    endsOn: slice.endsOn,
  );
}

String wireDateForOccurrence(DateTime scheduledDate) {
  return toCalendarDateString(calendarDateOnly(scheduledDate))!;
}
