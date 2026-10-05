import 'package:flutter/material.dart';

import '../../../../../core/theme/app_color_tokens.dart';

/// Compact status chip for occurrence zones (Overdue, Due, Coming up).
class CareItemStatusPill extends StatelessWidget {
  const CareItemStatusPill({
    super.key,
    required this.label,
    this.tone = CareItemStatusTone.neutral,
    this.leadingIcon,
  });

  final String label;
  final CareItemStatusTone tone;

  /// Extra cue when colour alone is not enough (FR-4, AC-C1).
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (background, foreground) = switch (tone) {
      CareItemStatusTone.overdue => (
        AppColorTokens.dangerLight,
        AppColorTokens.danger,
      ),
      CareItemStatusTone.due => (
        AppColorTokens.petCareLight,
        AppColorTokens.petCarePrimary,
      ),
      CareItemStatusTone.notRecorded => (
        AppColorTokens.infoLight,
        AppColorTokens.info,
      ),
      CareItemStatusTone.notRecordedClosed => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
      ),
      CareItemStatusTone.neutral => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Open past-due slots use [overdue]. Auto-closed Not recorded uses [notRecordedClosed].
enum CareItemStatusTone {
  neutral,
  due,
  overdue,
  notRecorded,
  notRecordedClosed,
}
