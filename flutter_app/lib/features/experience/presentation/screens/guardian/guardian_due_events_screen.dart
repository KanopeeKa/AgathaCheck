import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../../pet_profile/presentation/widgets/pet_list/due_event_row.dart';
import 'add_event_type_picker_sheet.dart';

/// Guardian events screen (`/g/events`) — due health/weight/other items (D17).
class GuardianDueEventsScreen extends ConsumerWidget {
  const GuardianDueEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final petsAsync = ref.watch(petListProvider);
    final entriesAsync = ref.watch(healthEntriesNotifierProvider);
    final controller = PetListController();

    return petsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (allPets) {
        final shellPets = controller.guardianShellPets(allPets);

        return entriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (entries) {
            final petIds = shellPets.map((p) => p.id).toSet();
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

            final petMap = {for (final p in shellPets) p.id: p};

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.eventsNavLabel,
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => showAddEventTypePickerSheet(
                          context,
                          pets: shellPets,
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l.addAnEvent),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: dueEntries.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 64,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l.homeAllCaughtUp,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l.homeNoDueEvents,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            ref.invalidate(healthEntriesNotifierProvider);
                          },
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: dueEntries
                                .map(
                                  (entry) => DueEventRow(
                                    entry: entry,
                                    pet: petMap[entry.petId],
                                    showInlineActions: true,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
