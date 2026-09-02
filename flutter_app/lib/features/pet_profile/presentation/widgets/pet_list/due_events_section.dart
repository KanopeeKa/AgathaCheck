import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/experience_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../health_tracking/presentation/widgets/care_event_row_context.dart';
import '../../../../health_tracking/presentation/widgets/care_event_row_host.dart';
import 'home_event_actions.dart';
import '../../../domain/entities/pet.dart';

class DueEventsSection extends ConsumerWidget {
  const DueEventsSection({required this.pets, this.showInlineActions = false});

  final List<Pet> pets;

  /// Legacy flag — row-level Done uses occurrence stack when needed.
  final bool showInlineActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(healthEntriesNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final xp = context.experienceColors;
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
                            ? xp.success
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
                      (entry) => CareEventRowHost(
                        key: Key('pet_list_care_row_${entry.id}'),
                        entry: entry,
                        pet: petMap[entry.petId],
                        rowContext: CareEventRowContext.dashboard,
                        isCompleted: false,
                        onUndo: () {},
                        onView: () =>
                            HomeEventActions.viewEntry(context, entry),
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
