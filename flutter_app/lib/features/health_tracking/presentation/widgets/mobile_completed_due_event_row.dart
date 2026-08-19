import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';

/// Inline completed presentation for an optimistically completed mobile event.
///
/// The containing dashboard list owns the completion state. This widget only
/// renders its completed treatment and delegates Undo to [onUndo].
class MobileCompletedDueEventRow extends StatelessWidget {
  const MobileCompletedDueEventRow({
    super.key,
    required this.entry,
    required this.displayName,
    required this.onUndo,
  });

  final HealthEntry entry;
  final String displayName;
  final VoidCallback onUndo;

  static const _kMinTouchTarget = 48.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColorTokens.successLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 20,
                  color: AppColorTokens.success,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                label: l.completedEventSemanticLabel(entry.name, displayName),
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.lineThrough,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$displayName · ${l.completed}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColorTokens.success,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: l.dueEventRowUndoLabel(entry.name),
              excludeSemantics: true,
              onTap: onUndo,
              child: SizedBox(
                height: _kMinTouchTarget,
                child: TextButton(
                  onPressed: onUndo,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColorTokens.guardianCarePrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(64, _kMinTouchTarget),
                  ),
                  child: Text(
                    l.undoComplete.replaceAll('\n', ' '),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColorTokens.guardianCarePrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
