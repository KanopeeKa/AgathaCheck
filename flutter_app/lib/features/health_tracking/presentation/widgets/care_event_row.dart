import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/occurrence_scheduling.dart';
import 'care_event_row_context.dart';
import 'care_event_row_pet_avatar.dart';
import 'care_event_status_line.dart';
import 'health_entry_type_labels.dart';

/// Unified due/overdue event row for dashboard Care preview, pet profile, and
/// global `/g/events` lists.
///
/// Information-first layout: pet avatar, three metadata lines, one Done action.
/// Row tap opens the event view screen; snooze and edit live on view only.
class CareEventRow extends StatelessWidget {
  const CareEventRow({
    super.key,
    required this.entry,
    this.pet,
    required this.rowContext,
    required this.isCompleted,
    required this.onMarkDone,
    required this.onUndo,
    required this.onView,
    this.occurrenceSummary,
    this.showTopDivider = true,
    this.isMarkDoneEnabled = true,
  });

  final HealthEntry entry;
  final Pet? pet;
  final CareEventRowContext rowContext;
  final bool isCompleted;
  final VoidCallback onMarkDone;
  final VoidCallback onUndo;
  final VoidCallback onView;

  /// When set and [openCount] > 0, drives the occurrence-aware status line.
  final OccurrenceSummary? occurrenceSummary;
  final bool showTopDivider;
  final bool isMarkDoneEnabled;

  static const _kMinTouchTarget = 48.0;

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return _CompletedCareEventRow(
        entry: entry,
        pet: pet,
        rowContext: rowContext,
        onUndo: onUndo,
        onView: onView,
        showTopDivider: showTopDivider,
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final displayName = careEventRowDisplayPetName(pet, entry, l);
    final typeLabel = healthEntryTypeLabel(l, entry.type);
    final status = occurrenceSummary != null && occurrenceSummary!.openCount > 0
        ? formatOccurrenceCareEventStatusLine(
            entry,
            occurrenceSummary!,
            l,
            colorScheme,
            context: context,
          )
        : formatCareEventStatusLine(entry, l, colorScheme);

    final metadataLine = switch (rowContext) {
      CareEventRowContext.dashboard => '$displayName · $typeLabel',
      CareEventRowContext.pet => typeLabel,
    };

    final viewLabel = rowContext == CareEventRowContext.dashboard
        ? l.dueEventRowViewLabel(entry.name, displayName)
        : l.dueEventRowViewPetContextLabel(entry.name);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: showTopDivider
            ? Border(top: BorderSide(color: colorScheme.outlineVariant))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CareEventRowPetAvatar(
              pet: pet,
              petName: entry.petName,
              colorScheme: colorScheme,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                identifier: 'care_event_row_view_${entry.id}',
                button: true,
                label: viewLabel,
                excludeSemantics: true,
                child: InkWell(
                  onTap: onView,
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        metadataLine,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      _StatusLineText(
                        status: status,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              identifier: 'care_event_row_done_${entry.id}',
              label: l.dueEventRowMarkDoneLabel(entry.name),
              excludeSemantics: true,
              onTap: isMarkDoneEnabled ? onMarkDone : null,
              child: Tooltip(
                message: l.markAsDone,
                child: _MarkDoneButton(
                  key: Key('care_event_row_done_${entry.id}'),
                  onTap: isMarkDoneEnabled ? onMarkDone : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusLineText extends StatelessWidget {
  const _StatusLineText({
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
    if (suffix == null || status.statusColor == null) {
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
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: prefix,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: suffix,
            style: theme.textTheme.bodySmall?.copyWith(
              color: status.statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _MarkDoneButton extends StatelessWidget {
  const _MarkDoneButton({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CareEventRow._kMinTouchTarget,
      height: CareEventRow._kMinTouchTarget,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: onTap == null
                    ? AppColorTokens.guardianCareLight.withValues(alpha: 0.5)
                    : AppColorTokens.guardianCareLight,
                border: Border.all(
                  color: AppColorTokens.guardianCarePrimary.withValues(
                    alpha: onTap == null ? 0.4 : 1,
                  ),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.check,
                size: 18,
                color: AppColorTokens.guardianCarePrimary.withValues(
                  alpha: onTap == null ? 0.4 : 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletedCareEventRow extends StatelessWidget {
  const _CompletedCareEventRow({
    required this.entry,
    this.pet,
    required this.rowContext,
    required this.onUndo,
    required this.onView,
    required this.showTopDivider,
  });

  final HealthEntry entry;
  final Pet? pet;
  final CareEventRowContext rowContext;
  final VoidCallback onUndo;
  final VoidCallback onView;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final displayName = careEventRowDisplayPetName(pet, entry, l);
    final typeLabel = healthEntryTypeLabel(l, entry.type);

    final metadataLine = switch (rowContext) {
      CareEventRowContext.dashboard => '$displayName · $typeLabel',
      CareEventRowContext.pet => typeLabel,
    };

    final viewLabel = rowContext == CareEventRowContext.dashboard
        ? l.dueEventRowViewLabel(entry.name, displayName)
        : l.dueEventRowViewPetContextLabel(entry.name);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: showTopDivider
            ? Border(top: BorderSide(color: colorScheme.outlineVariant))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CareEventRowPetAvatar(
              pet: pet,
              petName: entry.petName,
              colorScheme: colorScheme,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                identifier: 'care_event_row_view_${entry.id}',
                button: true,
                label: viewLabel,
                excludeSemantics: true,
                child: InkWell(
                  onTap: onView,
                  borderRadius: BorderRadius.circular(8),
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
                        metadataLine,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.completed,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColorTokens.success,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              identifier: 'care_event_row_undo_${entry.id}',
              label: l.dueEventRowUndoLabel(entry.name),
              excludeSemantics: true,
              onTap: onUndo,
              child: SizedBox(
                height: CareEventRow._kMinTouchTarget,
                child: TextButton(
                  key: Key('care_event_row_undo_${entry.id}'),
                  onPressed: onUndo,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColorTokens.guardianCarePrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(64, CareEventRow._kMinTouchTarget),
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
