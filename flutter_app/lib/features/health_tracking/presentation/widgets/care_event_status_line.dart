import 'package:flutter/material.dart';

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
    this.suffixTreatment,
  });

  final String text;

  /// Localized status word appended after the date separator, e.g. "Overdue".
  final String? statusSuffix;

  /// Accessible treatment for [statusSuffix] — date portion stays neutral.
  final HealthEntryStatusTreatment? suffixTreatment;
}

CareEventStatusLine formatCareEventStatusLine(
  HealthEntry entry,
  AppLocalizations l,
  ColorScheme colorScheme,
) {
  if (entry.isCompleted) {
    return CareEventStatusLine(
      text: formatHealthEntryStatusLine(entry, l),
      suffixTreatment: completedStatusTreatment(),
    );
  }

  if (entry.isOverdue) {
    final date = entry.nextDueDate != null
        ? formatHealthEntryStatusDate(entry.nextDueDate!)
        : l.urgencyDueToday;
    return CareEventStatusLine(
      text: '$date · ${l.urgencyOverdue}',
      statusSuffix: l.urgencyOverdue,
      suffixTreatment: overdueStatusTreatment(colorScheme),
    );
  }

  if (entry.isDueToday) {
    return CareEventStatusLine(
      text: l.urgencyDueToday,
      statusSuffix: l.urgencyDueToday,
      suffixTreatment: dueTodayStatusTreatment(),
    );
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
        suffixTreatment: overdueStatusTreatment(colorScheme),
      );
    case OccurrenceZone.dueToday:
      if (headline.scheduledTime != null &&
          headline.scheduledTime!.isNotEmpty) {
        final instant = formatOccurrenceInstant(headline, l, context: context);
        final suffix = l.urgencyDueToday;
        return CareEventStatusLine(
          text: '$instant$openSuffix · $suffix',
          statusSuffix: suffix,
          suffixTreatment: dueTodayStatusTreatment(),
        );
      }
      return CareEventStatusLine(
        text: '${l.urgencyDueToday}$openSuffix',
        statusSuffix: summary.openCount == 1 ? l.urgencyDueToday : null,
        suffixTreatment: summary.openCount == 1
            ? dueTodayStatusTreatment()
            : null,
      );
    case OccurrenceZone.comingUp:
      final instant = formatOccurrenceInstant(headline, l, context: context);
      return CareEventStatusLine(text: '$instant$openSuffix');
  }
}

/// Renders [CareEventStatusLine] with neutral date text and accessible suffix chip.
class CareEventStatusLineView extends StatelessWidget {
  const CareEventStatusLineView({
    super.key,
    required this.status,
    required this.theme,
    required this.colorScheme,
  });

  final CareEventStatusLine status;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final suffix = status.statusSuffix;
    final treatment = status.suffixTreatment;
    if (suffix == null && treatment != null) {
      return HealthEntryStatusLabel(
        text: status.text,
        treatment: treatment,
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      );
    }
    if (suffix == null || treatment == null) {
      return Text(
        status.text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final prefix = status.text.substring(0, status.text.length - suffix.length);
    return Row(
      children: [
        Flexible(
          child: Text(
            prefix,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        HealthEntryStatusLabel(
          text: suffix,
          treatment: treatment,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
