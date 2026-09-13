import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';

/// Locale-aware `dd MMM yy` (e.g. `01 Jan 26`) for health entry status lines.
final DateFormat healthEntryStatusDateFormat = DateFormat('dd MMM yy');

String formatHealthEntryStatusDate(DateTime date) =>
    healthEntryStatusDateFormat.format(calendarDateOnly(date));

/// Date-only status text: [AppLocalizations.doneOn] when completed, otherwise due date.
String formatHealthEntryStatusLine(HealthEntry entry, AppLocalizations l) {
  if (entry.isCompleted) {
    final doneDate = entry.completedOn ?? entry.updatedAt ?? entry.startDate;
    return l.doneOn(formatHealthEntryStatusDate(doneDate));
  }
  if (entry.nextDueDate == null) return l.notSet;
  return formatHealthEntryStatusDate(entry.nextDueDate!);
}

enum HealthEntryStatusKind {
  completed,
  overdue,
  dueToday,
  dueSoon,
  scheduled,
  neutral,
}

/// Accessible status colours: semantic foreground on optional subtle background.
class HealthEntryStatusTreatment {
  const HealthEntryStatusTreatment({
    required this.kind,
    required this.icon,
    required this.foregroundColor,
    this.iconColor,
    this.backgroundColor,
  });

  final HealthEntryStatusKind kind;
  final IconData icon;
  final Color foregroundColor;
  final Color? iconColor;
  final Color? backgroundColor;

  Color get resolvedIconColor => iconColor ?? foregroundColor;

  bool get usesChip => backgroundColor != null;
}

HealthEntryStatusTreatment healthEntryStatusTreatment(
  HealthEntry entry,
  ColorScheme colorScheme,
) {
  if (entry.isCompleted) {
    return const HealthEntryStatusTreatment(
      kind: HealthEntryStatusKind.completed,
      icon: Icons.check_circle_outline,
      foregroundColor: AppColorTokens.body,
      iconColor: AppColorTokens.success,
      backgroundColor: AppColorTokens.successLight,
    );
  }
  if (entry.isOverdue) {
    return const HealthEntryStatusTreatment(
      kind: HealthEntryStatusKind.overdue,
      icon: Icons.error_outline,
      foregroundColor: AppColorTokens.body,
      iconColor: AppColorTokens.danger,
      backgroundColor: AppColorTokens.dangerLight,
    );
  }
  if (entry.isDueToday) {
    return const HealthEntryStatusTreatment(
      kind: HealthEntryStatusKind.dueToday,
      icon: Icons.today_outlined,
      foregroundColor: AppColorTokens.body,
      iconColor: AppColorTokens.warning,
      backgroundColor: AppColorTokens.warningLight,
    );
  }
  if (entry.isDueSoon) {
    return const HealthEntryStatusTreatment(
      kind: HealthEntryStatusKind.dueSoon,
      icon: Icons.schedule_outlined,
      foregroundColor: AppColorTokens.body,
      iconColor: AppColorTokens.warning,
      backgroundColor: AppColorTokens.warningLight,
    );
  }
  if (entry.nextDueDate != null) {
    return HealthEntryStatusTreatment(
      kind: HealthEntryStatusKind.scheduled,
      icon: Icons.event_outlined,
      foregroundColor: colorScheme.primary,
      backgroundColor: null,
    );
  }
  return HealthEntryStatusTreatment(
    kind: HealthEntryStatusKind.neutral,
    icon: Icons.help_outline,
    foregroundColor: colorScheme.onSurfaceVariant,
    backgroundColor: null,
  );
}

/// Foreground colour for status glyphs — prefer [healthEntryStatusTreatment].
Color healthEntryStatusColor(HealthEntry entry, ColorScheme colorScheme) {
  return healthEntryStatusTreatment(entry, colorScheme).foregroundColor;
}

HealthEntryStatusTreatment overdueStatusTreatment(ColorScheme colorScheme) {
  return const HealthEntryStatusTreatment(
    kind: HealthEntryStatusKind.overdue,
    icon: Icons.error_outline,
    foregroundColor: AppColorTokens.body,
    iconColor: AppColorTokens.danger,
    backgroundColor: AppColorTokens.dangerLight,
  );
}

HealthEntryStatusTreatment dueTodayStatusTreatment() {
  return const HealthEntryStatusTreatment(
    kind: HealthEntryStatusKind.dueToday,
    icon: Icons.today_outlined,
    foregroundColor: AppColorTokens.body,
    iconColor: AppColorTokens.warning,
    backgroundColor: AppColorTokens.warningLight,
  );
}

HealthEntryStatusTreatment completedStatusTreatment() {
  return const HealthEntryStatusTreatment(
    kind: HealthEntryStatusKind.completed,
    icon: Icons.check_circle_outline,
    foregroundColor: AppColorTokens.body,
    iconColor: AppColorTokens.success,
    backgroundColor: AppColorTokens.successLight,
  );
}

/// Status line with icon and accessible semantic treatment (text + icon, never colour alone).
class HealthEntryStatusLabel extends StatelessWidget {
  const HealthEntryStatusLabel({
    super.key,
    required this.text,
    required this.treatment,
    this.style,
    this.compact = true,
  });

  final String text;
  final HealthEntryStatusTreatment treatment;
  final TextStyle? style;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = (style ?? theme.textTheme.bodySmall)?.copyWith(
      color: treatment.foregroundColor,
      fontWeight: FontWeight.w600,
      fontSize: compact ? 11 : null,
    );

    final icon = Icon(
      treatment.icon,
      size: compact ? 13 : 16,
      color: treatment.resolvedIconColor,
    );

    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (!treatment.usesChip) return label;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: treatment.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: label,
      ),
    );
  }
}
