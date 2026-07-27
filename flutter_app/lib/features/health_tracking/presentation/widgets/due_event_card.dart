import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/widgets/pet_list/home_event_actions.dart';
import '../../domain/entities/health_entry.dart';
import 'health_entry_card_actions.dart';
import 'health_entry_card_pet_strip.dart';
import 'health_entry_status.dart';

/// Unified due/overdue event card with pet strip and inline action columns.
class DueEventCard extends ConsumerWidget {
  const DueEventCard({
    super.key,
    required this.entry,
    this.pet,
    this.showActions = true,
  });

  final HealthEntry entry;
  final Pet? pet;
  final bool showActions;

  static const petStripWidth = 52.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    final statusColor = healthEntryStatusColor(entry, colorScheme);
    final statusLine = formatHealthEntryStatusLine(entry, l);
    final statusText = statusLine.toLowerCase();
    final displayName = pet?.name ?? entry.petName ?? '?';

    final showActionColumns = showActions && !entry.isCompleted;

    return MergeSemantics(
      child: Semantics(
        label:
            '${entry.name}, ${entry.type.label}, $statusText, for $displayName',
        child: Card(
          elevation: 0.5,
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HealthEntryPetStrip(
                  pet: pet,
                  petName: entry.petName,
                  colorScheme: colorScheme,
                ),
                Expanded(
                  child: InkWell(
                    onTap: showActionColumns
                        ? null
                        : () => HomeEventActions.openEntry(context, entry),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              ExcludeSemantics(
                                child: Icon(
                                  _typeIcon(entry.type),
                                  color: colorScheme.primary,
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
                                child: Icon(
                                  Icons.schedule,
                                  size: 13,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  statusLine,
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
                      ),
                    ),
                  ),
                ),
                if (showActionColumns) ...[
                  HealthEntryOpenButton(
                    semanticKey: Key('due_event_open_${entry.id}'),
                    onPressed: () => HomeEventActions.openEntry(context, entry),
                  ),
                  HealthEntrySnoozeButton(
                    onSnooze: (days) =>
                        HomeEventActions.snoozeDays(context, ref, entry, days),
                  ),
                  HealthEntryMarkDoneButton(
                    onPressed: () =>
                        HomeEventActions.markDone(context, ref, entry),
                    petStripWidth: petStripWidth,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(HealthEntryType type) {
    switch (type) {
      case HealthEntryType.medication:
        return Icons.medication;
      case HealthEntryType.preventive:
        return Icons.shield;
      case HealthEntryType.vetVisit:
        return Icons.local_hospital;
      case HealthEntryType.other:
        return Icons.more_horiz;
    }
  }
}
