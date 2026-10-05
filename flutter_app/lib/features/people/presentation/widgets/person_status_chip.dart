import 'package:flutter/material.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';

enum PersonStatusChipKind { inactive, needsReview, invited, accessUntil }

/// Status chip for person rows and headers — never colour alone.
class PersonStatusChip extends StatelessWidget {
  const PersonStatusChip({super.key, required this.kind, this.accessUntil});

  final PersonStatusChipKind kind;
  final DateTime? accessUntil;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final (label, icon, colors) = _resolve(theme, l);

    return Semantics(
      label: label,
      child: Chip(
        avatar: Icon(icon, size: 16, color: colors.foreground),
        label: Text(label),
        labelStyle: theme.textTheme.labelSmall?.copyWith(
          color: colors.foreground,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: colors.background,
        side: BorderSide(color: colors.border),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  (String, IconData, _ChipColors) _resolve(
    ThemeData theme,
    AppLocalizations l,
  ) {
    switch (kind) {
      case PersonStatusChipKind.inactive:
        return (
          l.peopleStatusInactive,
          Icons.pause_circle_outline,
          _ChipColors(
            background: theme.colorScheme.surfaceContainerHighest,
            foreground: theme.colorScheme.onSurfaceVariant,
            border: theme.colorScheme.outlineVariant,
          ),
        );
      case PersonStatusChipKind.needsReview:
        return (
          l.peopleStatusNeedsReview,
          Icons.flag_outlined,
          _ChipColors(
            background: theme.colorScheme.errorContainer,
            foreground: theme.colorScheme.onErrorContainer,
            border: theme.colorScheme.error.withValues(alpha: 0.35),
          ),
        );
      case PersonStatusChipKind.invited:
        return (
          l.invited,
          Icons.mail_outline,
          _ChipColors(
            background: theme.colorScheme.primaryContainer,
            foreground: theme.colorScheme.onPrimaryContainer,
            border: theme.colorScheme.primary.withValues(alpha: 0.25),
          ),
        );
      case PersonStatusChipKind.accessUntil:
        final date = accessUntil == null
            ? ''
            : formatCalendarDateMedium(accessUntil!);
        return (
          l.peopleAccessUntil(date),
          Icons.schedule_outlined,
          _ChipColors(
            background: theme.colorScheme.primaryContainer,
            foreground: theme.colorScheme.onPrimaryContainer,
            border: theme.colorScheme.primary.withValues(alpha: 0.25),
          ),
        );
    }
  }
}

class _ChipColors {
  const _ChipColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}
