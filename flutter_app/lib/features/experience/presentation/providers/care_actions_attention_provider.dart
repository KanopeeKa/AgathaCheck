import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../care_item/care_item.dart';
import '../../../health_tracking/health_tracking.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../pet_profile/pet_profile.dart';
import '../screens/pet_care/pet_care_due_events_screen.dart';

/// Overdue + due-today open care slots for the Guardian Actions list
/// (default filters, muted pets excluded). Shared with the Care tab badge.
final careActionsAttentionCountProvider = Provider<int>((ref) {
  final petsAsync = ref.watch(petListProvider);
  final entriesAsync = ref.watch(healthEntriesNotifierProvider);
  final historiesAsync = ref.watch(guardianGlobalEventHistoriesProvider);
  final mutedIds =
      ref.watch(notificationPreferencesProvider).valueOrNull?.mutedPetIds
          .toSet() ??
      {};

  if (petsAsync.isLoading ||
      entriesAsync.isLoading ||
      historiesAsync.isLoading) {
    return 0;
  }
  if (petsAsync.hasError || entriesAsync.hasError || historiesAsync.hasError) {
    return 0;
  }

  final shellPets = PetListController()
      .guardianShellPets(petsAsync.valueOrNull ?? [])
      .where((p) => !mutedIds.contains(p.id))
      .toList();
  if (shellPets.isEmpty) return 0;

  const filters = PetCareGlobalEventsFilters();
  final visible = filterPetCareGlobalEvents(
    entriesAsync.valueOrNull ?? [],
    shellPets,
    filters,
    historiesAsync.valueOrNull ?? {},
  );
  final agenda = buildCareAgenda<HealthEntry>(visible, (e) => e.schedule);
  return agenda.overdueCount + agenda.dueTodayCount;
});
