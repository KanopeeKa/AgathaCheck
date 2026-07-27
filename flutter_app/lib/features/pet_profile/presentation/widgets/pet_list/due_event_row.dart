import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/experience_colors.dart';
import '../../../../../core/utils/constants.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../domain/entities/pet.dart';
import 'home_event_actions.dart';

/// Single due/overdue event row with optional inline actions.
class DueEventRow extends ConsumerWidget {
  const DueEventRow({
    super.key,
    required this.entry,
    required this.pet,
    required this.showInlineActions,
  });

  final HealthEntry entry;
  final Pet? pet;
  final bool showInlineActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final xp = context.experienceColors;
    final l = AppLocalizations.of(context)!;
    final petColor = pet?.colorValue != null
        ? Color(pet!.colorValue!)
        : colorScheme.primary;
    final isOverdue = entry.isOverdue;
    final dateFormat = DateFormat.yMMMd();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => HomeEventActions.openPet(context, entry.petId),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: petColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (pet != null) ...[
                                      AppConstants.speciesIconWidget(
                                        pet!.species,
                                        size: 14,
                                        color: petColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        pet!.name,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: petColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Icon(
                                      _entryTypeIcon(entry.type),
                                      size: 13,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        entry.name,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isOverdue
                                  ? colorScheme.error.withAlpha(20)
                                  : xp.warning.withAlpha(51),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isOverdue
                                  ? dateFormat.format(entry.nextDueDate!)
                                  : l.today,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isOverdue
                                    ? colorScheme.error
                                    : xp.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showInlineActions)
            Padding(
              padding: const EdgeInsets.only(left: 13, top: 2),
              child: Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    key: Key('due_event_open_${entry.id}'),
                    onPressed: () =>
                        HomeEventActions.openPet(context, entry.petId),
                    child: Text(l.open),
                  ),
                  TextButton(
                    key: Key('due_event_snooze_${entry.id}'),
                    onPressed: () =>
                        HomeEventActions.snooze(context, ref, entry),
                    child: Text(l.snooze),
                  ),
                  TextButton(
                    key: Key('due_event_done_${entry.id}'),
                    onPressed: () =>
                        HomeEventActions.markDone(context, ref, entry),
                    child: Text(l.markAsDone),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _entryTypeIcon(HealthEntryType type) {
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
