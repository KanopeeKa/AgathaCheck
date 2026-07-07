import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_history_entry.dart';

/// Single-line history narrative for reports and detail views.
String formatEventHistoryLine(
  HealthHistoryEntry entry,
  AppLocalizations l,
  DateFormat dateFormat,
  DateFormat dateTimeFormat,
) {
  return l.eventHistoryLine(
    entry.dueDate != null ? dateFormat.format(entry.dueDate!) : l.notSet,
    entry.completedOn != null
        ? dateFormat.format(entry.completedOn!)
        : l.notSet,
    dateTimeFormat.format(entry.markedAt),
    entry.markedByName?.isNotEmpty == true
        ? entry.markedByName!
        : l.unknownUser,
  );
}
