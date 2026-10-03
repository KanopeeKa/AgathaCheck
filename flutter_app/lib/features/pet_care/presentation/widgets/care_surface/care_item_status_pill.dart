import 'package:flutter/material.dart';

import '../../../../../core/theme/app_color_tokens.dart';

/// Compact status chip for occurrence zones (Overdue, Due, Coming up).
class CareItemStatusPill extends StatelessWidget {
  const CareItemStatusPill({
    super.key,
    required this.label,
    this.tone = CareItemStatusTone.neutral,
  });

  final String label;
  final CareItemStatusTone tone;

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
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// `notRecorded` uses info tokens, not error (D-CIE-024, UIR-3).
enum CareItemStatusTone { neutral, due, overdue, notRecorded }
