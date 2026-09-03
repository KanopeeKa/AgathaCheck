import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/shell_return_navigation.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../health_tracking/presentation/widgets/add_health_entry_navigation.dart';
import '../providers/pet_providers.dart';
import 'widgets/manage_events_collection_filter.dart';
import 'widgets/pet_event_entry_list.dart';
import '../../../experience/domain/entities/app_experience.dart';

/// Manage pet events — unified list with filters linking to view entry.
class PetManageEventsScreen extends ConsumerWidget {
  const PetManageEventsScreen({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final petsAsync = ref.watch(allPetsIncludingOrgProvider);
    final experience = AppExperience.guardian;

    return petsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      data: (pets) {
        final pet = pets.where((p) => p.id == petId).firstOrNull;
        if (pet == null) {
          return Scaffold(body: Center(child: Text(l.petNotFound)));
        }

        return ExperienceShellScaffold(
          experience: experience,
          currentLocation: GoRouterState.of(context).uri.path,
          screenTitle: l.manageEvents,
          backPath: petDetailBackPath(context, petId),
          contextualActions: [
            IconButton(
              key: const Key('manage_events_add_app_bar'),
              tooltip: l.addAnEvent,
              icon: const Icon(Icons.add),
              onPressed: () => navigateToAddHealthEntry(context, petId: petId),
            ),
          ],
          child: ManageEventsList(petId: petId),
        );
      },
    );
  }
}

/// Unified manage-events list with filters and compact cards.
class ManageEventsList extends ConsumerStatefulWidget {
  const ManageEventsList({super.key, required this.petId});

  final String petId;

  @override
  ConsumerState<ManageEventsList> createState() => _ManageEventsListState();
}

class _ManageEventsListState extends ConsumerState<ManageEventsList> {
  ManageEventsFilters _filters = const ManageEventsFilters();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entriesAsync = ref.watch(petHealthEntriesByIdProvider(widget.petId));
    final historiesAsync = ref.watch(
      petManageEventHistoriesProvider(widget.petId),
    );

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(l.errorWithMessage('$error'))),
      data: (entries) {
        return historiesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text(l.errorWithMessage('$error'))),
          data: (histories) {
            final visible = filterAndSortManageEvents(
              entries,
              _filters,
              histories,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      l.eventsNavLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PetManageEventsCollectionFilterBar(
                    filters: _filters,
                    onChanged: (filters) => setState(() => _filters = filters),
                  ),
                  if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l.noEntriesYet,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = visible[index];
                        return EventListCard(
                          entry: entry,
                          history: histories[entry.id] ?? const [],
                          petId: widget.petId,
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
