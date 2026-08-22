import 'package:flutter/material.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/widgets/due_event_card.dart';
import '../../../../health_tracking/presentation/widgets/health_entry_card_actions.dart';
import '../../../../health_tracking/presentation/widgets/health_entry_card_pet_strip.dart';
import '../../../../health_tracking/presentation/widgets/health_entry_status.dart';
import '../../../../health_tracking/presentation/widgets/health_entry_type_labels.dart';
import '../../../../pet_profile/domain/entities/pet.dart';

/// Desktop/wide-layout care row with injected optimistic completion/undo
/// callbacks.
///
/// Due entries show the pet strip, entry body, and mark-done action column
/// (matching [DueEventCard]'s layout but routing mark-done through the
/// list-level optimistic state rather than the card's own fire-and-forget
/// wiring). Optimistically-completed entries show [_DesktopCompletedRow].
///
/// **Semantics:** the card container carries a non-actionable description
/// label; each interactive control (Open body area, Open button, Mark Done /
/// Undo) is an independently labelled, independently focusable node.
/// [MergeSemantics] is intentionally absent — merging would collapse the
/// independent actions into a single node and prevent assistive-technology
/// users from targeting them separately.
class DesktopCareRow extends StatelessWidget {
  const DesktopCareRow({
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
  final bool isCompleted;
  final VoidCallback onMarkDone;
  final VoidCallback onUndo;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return _DesktopCompletedRow(entry: entry, pet: pet, onUndo: onUndo);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final statusColor = healthEntryStatusColor(entry, colorScheme);

    final displayName = pet?.name ?? entry.petName ?? l.unknownPet;
    final typeLabel = healthEntryTypeLabel(l, entry.type);

    // Non-actionable container description — no MergeSemantics so each
    // interactive child retains its own independent semantic node.
    return Semantics(
      container: true,
      label: '${entry.name}, $typeLabel, $displayName',
      explicitChildNodes: true,
      child: Card(
        elevation: 0.5,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: HealthEntryPetStrip(
                  pet: pet,
                  petName: entry.petName,
                  colorScheme: colorScheme,
                ),
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  label: l.dueEventRowOpenLabel(entry.name, displayName),
                  onTap: onOpen,
                  child: InkWell(
                    onTap: onOpen,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: ExcludeSemantics(
                        child: _EntryBody(
                          entry: entry,
                          statusColor: statusColor,
                          l: l,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!entry.isCompleted) ...[
                Semantics(
                  button: true,
                  label: l.dueEventRowOpenLabel(entry.name, displayName),
                  onTap: onOpen,
                  child: ExcludeSemantics(
                    child: HealthEntryOpenButton(
                      semanticKey: Key('desktop_care_open_${entry.id}'),
                      onPressed: onOpen,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: l.dueEventRowMarkDoneLabel(entry.name),
                  onTap: onMarkDone,
                  child: ExcludeSemantics(
                    child: HealthEntryMarkDoneButton(
                      key: Key('desktop_care_done_${entry.id}'),
                      onPressed: onMarkDone,
                      petStripWidth: DueEventCard.petStripWidth,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryBody extends StatelessWidget {
  const _EntryBody({
    required this.entry,
    required this.statusColor,
    required this.l,
  });

  final HealthEntry entry;
  final Color statusColor;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                _typeIcon(entry.type),
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            ExcludeSemantics(
              child: Icon(Icons.schedule, size: 13, color: statusColor),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                formatHealthEntryStatusLine(entry, l),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _typeIcon(HealthEntryType type) => switch (type) {
    HealthEntryType.medication => Icons.medication,
    HealthEntryType.preventive => Icons.shield,
    HealthEntryType.vetVisit => Icons.local_hospital,
    HealthEntryType.other => Icons.more_horiz,
  };
}

/// Inline completed presentation for an optimistically-completed desktop row.
class _DesktopCompletedRow extends StatelessWidget {
  const _DesktopCompletedRow({
    required this.entry,
    this.pet,
    required this.onUndo,
  });

  final HealthEntry entry;
  final Pet? pet;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    final displayName = pet?.name ?? entry.petName ?? l.unknownPet;

    return Semantics(
      container: true,
      label: l.completedEventSemanticLabel(entry.name, displayName),
      explicitChildNodes: true,
      child: Card(
        elevation: 0.5,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: HealthEntryPetStrip(
                  pet: pet,
                  petName: entry.petName,
                  colorScheme: colorScheme,
                ),
              ),
              Expanded(
                child: ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.lineThrough,
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
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: l.dueEventRowUndoLabel(entry.name),
                onTap: onUndo,
                child: ExcludeSemantics(
                  child: HealthEntryUndoCompleteButton(
                    key: Key('desktop_care_undo_${entry.id}'),
                    onPressed: onUndo,
                    petStripWidth: DueEventCard.petStripWidth,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
