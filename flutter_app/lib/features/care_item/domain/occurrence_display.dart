import '../../../l10n/app_localizations.dart';
import 'care_occurrence.dart';
import 'occurrence_detail.dart';

enum OccurrencePillTone {
  overdue,
  due,
  notRecorded,
  closedNotRecorded,
  neutral,
}

class OccurrencePillStyle {
  const OccurrencePillStyle({required this.label, required this.tone});

  final String label;
  final OccurrencePillTone tone;
}

/// Status pill label and tone for an open occurrence row (FR-4).
OccurrencePillStyle openOccurrencePillStyle(
  AppLocalizations l,
  CareOccurrenceStatus status,
) {
  return switch (status) {
    CareOccurrenceStatus.overdue => OccurrencePillStyle(
      label: l.urgencyOverdue,
      tone: OccurrencePillTone.overdue,
    ),
    CareOccurrenceStatus.notRecorded => OccurrencePillStyle(
      label: l.careStatusNotRecorded,
      tone: OccurrencePillTone.neutral,
    ),
    CareOccurrenceStatus.due => OccurrencePillStyle(
      label: l.careStatusDue,
      tone: OccurrencePillTone.due,
    ),
    CareOccurrenceStatus.comingUp => OccurrencePillStyle(
      label: l.careStatusComingUp,
      tone: OccurrencePillTone.neutral,
    ),
    CareOccurrenceStatus.done => OccurrencePillStyle(
      label: l.done,
      tone: OccurrencePillTone.neutral,
    ),
    CareOccurrenceStatus.skipped => OccurrencePillStyle(
      label: l.careSkip,
      tone: OccurrencePillTone.neutral,
    ),
    CareOccurrenceStatus.unknown => OccurrencePillStyle(
      label: l.careStatusComingUp,
      tone: OccurrencePillTone.neutral,
    ),
  };
}

/// Status pill on the Care date screen (open + closed doses).
OccurrencePillStyle occurrenceStatusPillStyle(
  AppLocalizations l,
  CareOccurrence occ,
) {
  if (occ.isClosedNotRecorded) {
    return closedNotRecordedPillStyle(l);
  }
  return openOccurrencePillStyle(l, occ.status);
}

/// Status pill for an upcoming-group row (Later today vs Coming up).
OccurrencePillStyle upcomingOccurrencePillStyle(
  AppLocalizations l, {
  required bool laterToday,
}) {
  if (laterToday) {
    return OccurrencePillStyle(
      label: l.occurrenceLaterToday,
      tone: OccurrencePillTone.neutral,
    );
  }
  return OccurrencePillStyle(
    label: l.occurrenceZoneComingUp,
    tone: OccurrencePillTone.neutral,
  );
}

/// Status pill for a closed Not recorded dose (grey, not actionable as overdue).
OccurrencePillStyle closedNotRecordedPillStyle(AppLocalizations l) {
  return OccurrencePillStyle(
    label:
        '${l.careStatusNotRecorded} (${l.careStatusNotRecordedClosedMarker})',
    tone: OccurrencePillTone.closedNotRecorded,
  );
}

/// Screen reader label for a closed Not recorded care (AC-C7).
String closedNotRecordedSemantics(AppLocalizations l) =>
    '${l.careStatusNotRecorded}, ${l.careStatusNotRecordedClosedMarker}';

/// Status line on the occurrence screen header.
String occurrenceStatusLine(AppLocalizations l, CareOccurrence occ) {
  if (occ.isClosedNotRecorded) {
    return closedNotRecordedPillStyle(l).label;
  }
  return switch (occ.status) {
    CareOccurrenceStatus.overdue => l.urgencyOverdue,
    CareOccurrenceStatus.notRecorded => l.urgencyOverdue,
    CareOccurrenceStatus.due => l.careStatusDue,
    CareOccurrenceStatus.done => l.done,
    CareOccurrenceStatus.skipped => l.careSkip,
    _ => l.careStatusComingUp,
  };
}
