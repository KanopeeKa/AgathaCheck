import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../domain/entities/health_entry.dart';
import 'health_entry_status.dart';
import 'health_entry_type_labels.dart';
import 'mobile_completed_due_event_row.dart';

/// Compact mobile row for a due/overdue health entry.
///
/// Used in the Guardian dashboard at phone-width breakpoints (<600dp).
///
/// This is a focused presentation component. It holds NO authoritative
/// optimistic-completion state; that state is owned by the list
/// ([GuardianUpcomingEventsSection]) and passed in via [isCompleted]:
///
///  * When [isCompleted] is false the row shows the due/overdue presentation
///    with an Open action and a Mark-done action ([onMarkDone]).
///  * When [isCompleted] is true the row shows the completed presentation
///    (filled check, completed text) with an Undo action ([onUndo]).
///
/// Open and complete/reopen controls are separately labelled and independently
/// usable. Desktop/tablet paths ([DueEventCard]) are unchanged.
class MobileDueEventRow extends StatelessWidget {
  const MobileDueEventRow({
    super.key,
    required this.entry,
    this.pet,
    required this.isCompleted,
    required this.onMarkDone,
    required this.onUndo,
    required this.onOpen,
  });

  final HealthEntry entry;
  final Pet? pet;

  /// Whether the row should render the completed presentation. Driven by the
  /// list-level optimistic state, not by the entry itself.
  final bool isCompleted;

  /// Called when the user taps the mark-done control (due presentation).
  final VoidCallback onMarkDone;

  /// Called when the user taps the undo control (completed presentation).
  final VoidCallback onUndo;

  /// Called when the user taps the row body to open the entry.
  final VoidCallback onOpen;

  /// Minimum touch target size per design rules.
  static const _kMinTouchTarget = 48.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    final displayName = pet?.name ?? entry.petName ?? l.unknownPet;

    if (isCompleted) {
      return MobileCompletedDueEventRow(
        entry: entry,
        displayName: displayName,
        onUndo: onUndo,
      );
    }

    final statusLine = _urgencyText(entry, l);

    // Accessible label: name, localized type, urgency, pet name — no '?', no
    // English joining words, no entry.type.label.
    final typeLabel = healthEntryTypeLabel(l, entry.type);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status icon chip (decorative — excluded from semantics)
            _StatusChip(entry: entry),
            const SizedBox(width: 12),

            // Event name + detail — independently labelled open action
            Expanded(
              child: Semantics(
                button: true,
                label: l.dueEventRowOpenLabel(entry.name, displayName),
                excludeSemantics: true,
                onTap: onOpen,
                child: InkWell(
                  onTap: onOpen,
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
                        '$displayName · $typeLabel · $statusLine',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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

            // Mark-done button — separately labelled, independent from open
            Semantics(
              button: true,
              label: l.dueEventRowMarkDoneLabel(entry.name),
              excludeSemantics: true,
              onTap: onMarkDone,
              child: Tooltip(
                message: l.markAsDone,
                child: _MarkDoneButton(onTap: onMarkDone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Urgency text used in the subtitle and derived from the entry's due state.
/// Returns localized strings — no English literals.
String _urgencyText(HealthEntry entry, AppLocalizations l) {
  if (entry.isOverdue) return l.urgencyOverdue;
  if (entry.isDueToday) return l.urgencyDueToday;
  if (entry.nextDueDate != null) {
    return l.urgencyDueDate(formatHealthEntryStatusDate(entry.nextDueDate!));
  }
  return l.urgencyDueToday;
}

/// Colored status-icon chip matching the mockup design.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.entry});

  final HealthEntry entry;

  @override
  Widget build(BuildContext context) {
    final isOverdue = entry.isOverdue;

    final bg = isOverdue
        ? AppColorTokens.warmAccentLight
        : AppColorTokens.guardianCareLight;
    final fg = isOverdue
        ? AppColorTokens.danger
        : AppColorTokens.guardianCareActive;

    return ExcludeSemantics(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isOverdue ? Icons.schedule : Icons.calendar_today_outlined,
          size: 18,
          color: fg,
        ),
      ),
    );
  }
}

/// The check-to-complete button (unfilled → indicates action to take).
class _MarkDoneButton extends StatelessWidget {
  const _MarkDoneButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MobileDueEventRow._kMinTouchTarget,
      height: MobileDueEventRow._kMinTouchTarget,
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
                color: AppColorTokens.guardianCareLight,
                border: Border.all(
                  color: AppColorTokens.guardianCarePrimary,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.check,
                size: 18,
                color: AppColorTokens.guardianCarePrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
