import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/health_tracking.dart';
import '../../../../pet_profile/pet_profile.dart';
import '../../pet_profile/screens/widgets/manage_events_filters.dart';
import '../../pet_profile/screens/widgets/pet_care_global_events_filters.dart';

import 'global_events_list.dart';
export 'global_events_list.dart' show GlobalEventsList;
export '../../pet_profile/screens/widgets/pet_care_global_events_filters.dart'
    show PetCareEventsCohortFilter, PetCareGlobalEventsFilters;

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Histories for all guardian shell-pet entries (global events list).
final guardianGlobalEventHistoriesProvider =
    FutureProvider<Map<String, List<HealthHistoryEntry>>>((ref) async {
      final entries =
          ref.watch(healthEntriesNotifierProvider).valueOrNull ?? [];
      final pets = ref.watch(petListProvider).valueOrNull ?? [];
      final shellPetIds = PetListController()
          .guardianShellPets(pets)
          .map((pet) => pet.id)
          .toSet();
      final scoped = entries.where((e) => shellPetIds.contains(e.petId));
      final histories = <String, List<HealthHistoryEntry>>{};
      await Future.wait(
        scoped.map((entry) async {
          histories[entry.id] = await ref.read(
            entryHistoryProvider(entry.id).future,
          );
        }),
      );
      return histories;
    });

// ---------------------------------------------------------------------------
// Pure filter/sort functions
// ---------------------------------------------------------------------------

/// Returns the subset of [shellPets] that match the cohort and pet-id filters.
List<Pet> guardianGlobalEventsPets(
  List<Pet> shellPets,
  PetCareGlobalEventsFilters filters,
) {
  var pets = shellPets;

  if (filters.cohorts.isNotEmpty) {
    pets = pets.where((pet) {
      final matchesMyPets =
          filters.cohorts.contains(PetCareEventsCohortFilter.myPets) &&
          !pet.isFoster;
      final matchesFoster =
          filters.cohorts.contains(PetCareEventsCohortFilter.fosterPets) &&
          pet.isFoster;
      return matchesMyPets || matchesFoster;
    }).toList();
  }

  if (filters.petIds.isNotEmpty) {
    pets = pets.where((pet) => filters.petIds.contains(pet.id)).toList();
  }

  return pets;
}

/// Filters and sorts [entries] to the scoped pets and applied event filters.
List<HealthEntry> filterPetCareGlobalEvents(
  List<HealthEntry> entries,
  List<Pet> scopedPets,
  PetCareGlobalEventsFilters filters,
  Map<String, List<HealthHistoryEntry>> histories,
) {
  final petIds = scopedPets.map((pet) => pet.id).toSet();
  return entries
      .where((entry) => petIds.contains(entry.petId))
      .where(
        (entry) => matchesManageEventsFilters(
          entry,
          filters.eventFilters,
          histories[entry.id] ?? const [],
        ),
      )
      .toList();
}

// ---------------------------------------------------------------------------
// Screen widget
// ---------------------------------------------------------------------------

/// Guardian events screen (`/pc/events`) — unified list for all shell pets.
class PetCareDueEventsScreen extends ConsumerWidget {
  const PetCareDueEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final petsAsync = ref.watch(petListProvider);

    return petsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _PetLoadErrorView(
        message: l.careLoadError,
        onRetry: () => ref.invalidate(petListProvider),
      ),
      data: (allPets) {
        final shellPets = PetListController().guardianShellPets(allPets);
        return GlobalEventsList(shellPets: shellPets);
      },
    );
  }
}

class _PetLoadErrorView extends StatelessWidget {
  const _PetLoadErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton.icon(
              key: const Key('pet_load_error_retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }
}
