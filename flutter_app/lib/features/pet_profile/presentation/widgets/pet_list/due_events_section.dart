import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/constants.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../domain/entities/pet.dart';
import 'home_event_actions.dart';

class DueEventsSection extends ConsumerWidget {
  const DueEventsSection({
    required this.pets,
    this.showInlineActions = false,
  });

  final List<Pet> pets;
  final bool showInlineActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(healthEntriesNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return entriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (entries) {
        final petIds = pets.map((p) => p.id).toSet();
        final dueEntries =
            entries
                .where(
                  (e) =>
                      petIds.contains(e.petId) &&
                      !e.isCompleted &&
                      (e.isOverdue || e.isDueToday),
                )
                .toList()
              ..sort((a, b) {
                final ad = a.nextDueDate ?? DateTime(2100);
                final bd = b.nextDueDate ?? DateTime(2100);
                return ad.compareTo(bd);
              });

        final petMap = {for (final p in pets) p.id: p};

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: dueEntries.isEmpty
                    ? colorScheme.outlineVariant
                    : colorScheme.error.withAlpha(80),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        dueEntries.isEmpty
                            ? Icons.check_circle_outline
                            : Icons.schedule,
                        size: 20,
                        color: dueEntries.isEmpty
                            ? Colors.green
                            : colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dueEntries.isEmpty
                            ? l.homeAllCaughtUp
                            : l.upcomingEvents,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: dueEntries.isEmpty
                              ? colorScheme.onSurface
                              : colorScheme.error,
                        ),
                      ),
                      if (dueEntries.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${dueEntries.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (dueEntries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l.homeNoDueEvents,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (dueEntries.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...dueEntries.map(
                      (entry) => _DueEventRow(
                        entry: entry,
                        pet: petMap[entry.petId],
                        showInlineActions: showInlineActions,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DueEventRow extends ConsumerWidget {
  const _DueEventRow({
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
                                  : Colors.orange.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isOverdue
                                  ? dateFormat.format(entry.nextDueDate!)
                                  : l.today,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isOverdue
                                    ? colorScheme.error
                                    : Colors.orange[800],
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
      case HealthEntryType.procedure:
        return Icons.more_horiz;
      case HealthEntryType.familyEvent:
        return Icons.family_restroom;
    }
  }
}
