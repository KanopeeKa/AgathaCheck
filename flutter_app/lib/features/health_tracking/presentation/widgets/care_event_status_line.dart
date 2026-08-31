import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';
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
