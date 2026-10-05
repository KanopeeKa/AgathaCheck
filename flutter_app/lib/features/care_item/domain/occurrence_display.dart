import '../../../l10n/app_localizations.dart';
import 'care_occurrence.dart';
import 'occurrence_detail.dart';

enum OccurrencePillTone { overdue, due, notRecorded, neutral }

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
      label: l.careStatusNotRecordedOpen,
      tone: OccurrencePillTone.notRecorded,
    ),
    CareOccurrenceStatus.due => OccurrencePillStyle(
      label: l.careStatusDue,
      tone: OccurrencePillTone.due,
    ),
    _ => OccurrencePillStyle(
      label: l.careStatusComingUp,
      tone: OccurrencePillTone.neutral,
    ),
  };
}

/// Screen reader label for a closed Not recorded care (AC-C7).
String closedNotRecordedSemantics(AppLocalizations l) =>
    '${l.careStatusNotRecorded}, ${l.careStatusNotRecordedClosedMarker}';

/// Status line on the occurrence screen header.
String occurrenceStatusLine(AppLocalizations l, CareOccurrence occ) {
  if (occ.isClosedNotRecorded) {
    return '${l.careStatusNotRecorded} (${l.careStatusNotRecordedClosedMarker})';
  }
  return switch (occ.status) {
    CareOccurrenceStatus.overdue => l.urgencyOverdue,
    CareOccurrenceStatus.notRecorded => l.careStatusNotRecordedOpen,
    CareOccurrenceStatus.due => l.careStatusDue,
    CareOccurrenceStatus.done => l.done,
    CareOccurrenceStatus.skipped => l.careSkip,
    _ => l.careStatusComingUp,
  };
}
