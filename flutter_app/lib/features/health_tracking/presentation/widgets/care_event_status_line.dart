import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_occurrence.dart';
import '../../domain/occurrence_scheduling.dart';
import 'health_entry_status.dart';

/// Formatted third line for [CareEventRow]: date · status (single overdue signal).
class CareEventStatusLine {
  const CareEventStatusLine({
    required this.text,
    this.statusSuffix,
    this.statusColor,
  });

  final String text;

  /// Localized status word appended after the date separator, e.g. "Overdue".
  final String? statusSuffix;

  /// Applied to [statusSuffix] only — date portion stays neutral.
  final Color? statusColor;
}

CareEventStatusLine formatCareEventStatusLine(
  HealthEntry entry,
  AppLocalizations l,
  ColorScheme colorScheme,
) {
  if (entry.isCompleted) {
    return CareEventStatusLine(
      text: formatHealthEntryStatusLine(entry, l),
      statusColor: AppColorTokens.success,
    );
  }

  if (entry.isOverdue) {
    final date = entry.nextDueDate != null
        ? formatHealthEntryStatusDate(entry.nextDueDate!)
        : l.urgencyDueToday;
    return CareEventStatusLine(
      text: '$date · ${l.urgencyOverdue}',
      statusSuffix: l.urgencyOverdue,
      statusColor: colorScheme.error,
    );
  }

  if (entry.isDueToday) {
    return CareEventStatusLine(text: l.urgencyDueToday);
  }

  if (entry.nextDueDate != null) {
    return CareEventStatusLine(
      text: formatHealthEntryStatusDate(entry.nextDueDate!),
    );
  }

  return CareEventStatusLine(text: l.notSet);
}

/// Formats a single occurrence instant for list rows and stack sheet rows.
String formatOccurrenceInstant(
  HealthOccurrence occ,
  AppLocalizations l, {
  BuildContext? context,
}) {
  final date = formatHealthEntryStatusDate(occ.scheduledDate);
  final time = occ.scheduledTime;
  if (time == null || time.isEmpty) return date;
  final formattedTime = context != null
      ? _formatOccurrenceTimeLabel(context, time)
      : time;
  return l.occurrenceDateAtTime(date, formattedTime);
}

String _formatOccurrenceTimeLabel(BuildContext context, String time) {
  final parts = time.split(':');
  if (parts.length < 2) return time;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  return MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay(hour: hour, minute: minute));
}

/// Occurrence-aware third line for [CareEventRow] when open doses exist.
CareEventStatusLine formatOccurrenceCareEventStatusLine(
  HealthEntry entry,
  OccurrenceSummary summary,
  AppLocalizations l,
  ColorScheme colorScheme, {
  BuildContext? context,
}) {
  if (summary.openCount == 0) {
    return formatCareEventStatusLine(entry, l, colorScheme);
  }

  final now = DateTime.now();
  final headline = summary.missedCount > 0
      ? summary.missedHead
      : summary.nextHead;
  if (headline == null) {
    return formatCareEventStatusLine(entry, l, colorScheme);
  }

  final zone = occurrenceZone(headline, now);
  final openSuffix = summary.openCount > 1
      ? ' · ${l.occurrenceOpenCount(summary.openCount)}'
      : '';

  switch (zone) {
    case OccurrenceZone.missed:
      final suffix = l.urgencyOverdue;
      final missedSuffix = summary.missedCount > 1
          ? ' · ${l.occurrenceMissedCount(summary.missedCount)}'
          : '';
      final instant = formatOccurrenceInstant(headline, l, context: context);
      return CareEventStatusLine(
        text: '$instant$openSuffix$missedSuffix · $suffix',
        statusSuffix: suffix,
        statusColor: colorScheme.error,
      );
    case OccurrenceZone.dueToday:
      if (headline.scheduledTime != null &&
          headline.scheduledTime!.isNotEmpty) {
        final instant = formatOccurrenceInstant(headline, l, context: context);
        final suffix = l.urgencyDueToday;
        return CareEventStatusLine(
          text: '$instant$openSuffix · $suffix',
          statusSuffix: suffix,
          statusColor: AppColorTokens.warning,
        );
      }
      return CareEventStatusLine(
        text: '${l.urgencyDueToday}$openSuffix',
        statusSuffix: summary.openCount == 1 ? l.urgencyDueToday : null,
        statusColor: summary.openCount == 1 ? AppColorTokens.warning : null,
      );
    case OccurrenceZone.comingUp:
      final instant = formatOccurrenceInstant(headline, l, context: context);
      return CareEventStatusLine(text: '$instant$openSuffix');
  }
}
