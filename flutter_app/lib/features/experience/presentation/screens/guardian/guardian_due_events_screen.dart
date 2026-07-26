import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../health_tracking/presentation/widgets/guardian_add_event_picker_sheet.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../../pet_profile/presentation/widgets/pet_list/due_event_row.dart';

/// Guardian events screen (`/g/events`) — due and overdue health/other items.
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
            final dueEntries = guardianDueEntries(entries, petIds);
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
                          l.dueAndOverdue,
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => showGuardianAddEventPickerSheet(
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
