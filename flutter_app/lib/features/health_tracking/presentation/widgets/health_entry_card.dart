import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../domain/entities/health_entry.dart';
import 'health_entry_card_actions.dart';
import 'health_entry_card_pet_strip.dart';
import 'health_entry_status.dart';

class HealthEntryCard extends StatelessWidget {
  const HealthEntryCard({
    super.key,
    required this.entry,
    this.pet,
    this.onMarkTaken,
    this.onSnooze,
    this.onTap,
    this.onUndoComplete,
    this.healthIssueName,
  });

  final HealthEntry entry;
  final Pet? pet;
  final VoidCallback? onMarkTaken;
  final void Function(int days)? onSnooze;
  final VoidCallback? onTap;
  final VoidCallback? onUndoComplete;
  final String? healthIssueName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusColor = healthEntryStatusColor(entry, colorScheme);

    final statusLine = formatHealthEntryStatusLine(
      entry,
      AppLocalizations.of(context)!,
    );
    final statusText = statusLine.toLowerCase();

    final showActions = !entry.isCompleted;

    return MergeSemantics(
      child: Semantics(
        label:
            '${entry.name}, ${entry.type.label}, $statusText${pet != null
                ? ', for ${pet!.name}'
                : entry.petName != null
                ? ', for ${entry.petName}'
                : ''}',
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
                    onTap: onTap,
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
                                  entry.dosage.isNotEmpty
                                      ? '${entry.name} · ${entry.dosage}'
                                      : entry.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (healthIssueName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Row(
                                children: [
                                  ExcludeSemantics(
                                    child: Icon(
                                      Icons.health_and_safety,
                                      size: 12,
                                      color: colorScheme.tertiary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      healthIssueName!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.tertiary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
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
                              Text(
                                statusLine,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                              const Spacer(),
                              HealthEntryFrequencyBadge(
                                frequency: entry.frequency,
                                interval: entry.frequencyInterval,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (showActions && onMarkTaken != null) ...[
                  if (onSnooze != null)
                    HealthEntrySnoozeButton(onSnooze: onSnooze),
                  HealthEntryMarkDoneButton(
                    onPressed: onMarkTaken,
                    petStripWidth: 52,
                  ),
                ],
                if (entry.isCompleted) ...[
                  HealthEntryUndoCompleteButton(
                    onPressed: onUndoComplete,
                    petStripWidth: 52,
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
      case HealthEntryType.procedure:
        return Icons.more_horiz;
      case HealthEntryType.familyEvent:
        return Icons.family_restroom;
    }
  }
}
