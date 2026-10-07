import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../domain/entities/planned_absence.dart';

/// User-facing labels for a planned absence (title with date fallback).
class PlannedAbsenceDisplay {
  const PlannedAbsenceDisplay._();

  static String dateRangeLabel(AppLocalizations l, PlannedAbsence absence) {
    final start = parseCalendarDate(absence.startsOn);
    final end = parseCalendarDate(absence.endsOn);
    if (start != null && end != null) {
      return l.careContextAwayPreviewDateRange(
        formatCalendarDateDisplay(start),
        formatCalendarDateDisplay(end),
      );
    }
    return '${absence.startsOn} – ${absence.endsOn}';
  }

  static String primaryLabel(AppLocalizations l, PlannedAbsence absence) {
    final trimmed = absence.title?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return dateRangeLabel(l, absence);
  }

  /// When [title] is set, returns formatted dates for a secondary line.
  static String? secondaryDateLine(AppLocalizations l, PlannedAbsence absence) {
    final trimmed = absence.title?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return dateRangeLabel(l, absence);
  }
}
