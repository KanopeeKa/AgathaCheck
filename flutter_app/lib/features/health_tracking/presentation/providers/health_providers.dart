import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/auth/auth.dart';
import '../../application/health_data_providers.dart';
import '../../domain/entities/command_outcome.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_history_entry.dart';
import '../../domain/entities/health_occurrence.dart';
import '../../domain/usecases/create_health_entry.dart';
import '../../domain/usecases/delete_health_entry.dart';
import '../../domain/usecases/get_entry_history.dart';
import '../../domain/usecases/get_health_entries.dart';
import '../../domain/usecases/update_health_entry.dart';
import '../../domain/services/care_temporal_grouping_service.dart';

export '../../application/health_data_providers.dart';
export '../../application/health_documents_providers.dart';

part 'health_entries_store.dart';

/// Provides the get health entries use case.
final getHealthEntriesProvider = Provider<GetHealthEntries>((ref) {
  return GetHealthEntries(ref.watch(healthRepositoryProvider));
});

/// Provides the create health entry use case.
final createHealthEntryProvider = Provider<CreateHealthEntry>((ref) {
  return CreateHealthEntry(ref.watch(healthRepositoryProvider));
});

/// Provides the update health entry use case.
final updateHealthEntryProvider = Provider<UpdateHealthEntry>((ref) {
  return UpdateHealthEntry(ref.watch(healthRepositoryProvider));
});

/// Provides the delete health entry use case.
final deleteHealthEntryProvider = Provider<DeleteHealthEntry>((ref) {
  return DeleteHealthEntry(ref.watch(healthRepositoryProvider));
});

/// Provides the get entry history use case.
final getEntryHistoryProvider = Provider<GetEntryHistory>((ref) {
  return GetEntryHistory(ref.watch(healthRepositoryProvider));
});

/// Health entries for a specific pet, derived reactively from the global list
/// ([healthEntriesNotifierProvider]) so it reflects creates/edits/deletes without
/// a separate fetch.
final petHealthEntriesByIdProvider =
    Provider.family<AsyncValue<List<HealthEntry>>, String>((ref, petId) {
      final entriesAsync = ref.watch(healthEntriesNotifierProvider);
      return entriesAsync.whenData(
        (entries) => entries.where((e) => e.petId == petId).toList(),
      );
    });

/// Medication, preventive, and vet visit entries for the pet profile Health Events section.
final petHealthEventsByIdProvider =
    Provider.family<AsyncValue<List<HealthEntry>>, String>((ref, petId) {
      return ref
          .watch(petHealthEntriesByIdProvider(petId))
          .whenData(
            (entries) => entries.where((e) => e.type.isHealthEvent).toList(),
          );
    });

/// Care event and other entries for the pet profile Other events section.
final petOtherEventsByIdProvider =
    Provider.family<AsyncValue<List<HealthEntry>>, String>((ref, petId) {
      return ref
          .watch(petHealthEntriesByIdProvider(petId))
          .whenData(
            (entries) => entries.where((e) => e.type.isOtherEvent).toList(),
          );
    });

/// Whether a health entry is due or overdue within its [remindDaysBefore] window.
bool isEntryDueOrOverdue(HealthEntry entry) {
  return const CareTemporalGroupingService().groupForEntry(
        entry,
        DateTime.now(),
      ) !=
      null;
}

/// Guardian due inbox entries for shell pets, oldest due first.
List<HealthEntry> guardianDueEntries(
  List<HealthEntry> entries,
  Set<String> petIds,
) {
  final due =
      entries
          .where((e) => petIds.contains(e.petId) && isEntryDueOrOverdue(e))
          .toList()
        ..sort((a, b) {
          final ad = a.nextDueDate ?? DateTime(2100);
          final bd = b.nextDueDate ?? DateTime(2100);
          return ad.compareTo(bd);
        });
  return due;
}

/// True when at least one health entry is due today or overdue.
final hasDueOrOverdueEventsProvider = Provider<bool>((ref) {
  final entriesAsync = ref.watch(healthEntriesNotifierProvider);
  return entriesAsync.maybeWhen(
    data: (entries) => entries.any(isEntryDueOrOverdue),
    orElse: () => false,
  );
});

/// Provides history for a specific entry.
final entryHistoryProvider =
    FutureProvider.family<List<HealthHistoryEntry>, String>((ref, entryId) {
      return ref.read(getEntryHistoryProvider).call(entryId);
    });
