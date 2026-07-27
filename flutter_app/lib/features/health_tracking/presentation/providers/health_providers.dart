import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import '../../data/datasources/health_remote_datasource.dart';
import '../../data/repositories/health_repository_impl.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_history_entry.dart';
import '../../domain/repositories/health_repository.dart';
import '../../domain/usecases/create_health_entry.dart';
import '../../domain/usecases/delete_health_entry.dart';
import '../../domain/usecases/get_entry_history.dart';
import '../../domain/usecases/get_health_entries.dart';
import '../../domain/usecases/mark_entry_taken.dart';
import '../../domain/usecases/update_health_entry.dart';

final healthRemoteDataSourceProvider = Provider<HealthRemoteDataSource>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  final token = ref.watch(authProvider).accessToken;
  final ds = HealthRemoteDataSourceImpl(
    baseUrl: baseUrl,
    client: ref.watch(authHttpClientProvider),
  );
  ds.authToken = token;
  return ds;
});

final healthDataSourceProvider = Provider<HealthRemoteDataSourceImpl>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  final token = ref.watch(authProvider).accessToken;
  final ds = HealthRemoteDataSourceImpl(
    baseUrl: baseUrl,
    client: ref.watch(authHttpClientProvider),
  );
  ds.authToken = token;
  return ds;
});

/// Provides the health repository implementation.
final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final dataSource = ref.watch(healthRemoteDataSourceProvider);
  return HealthRepositoryImpl(dataSource);
});

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

/// Provides the mark entry taken use case.
final markEntryTakenProvider = Provider<MarkEntryTaken>((ref) {
  return MarkEntryTaken(ref.watch(healthRepositoryProvider));
});

/// Provides the get entry history use case.
final getEntryHistoryProvider = Provider<GetEntryHistory>((ref) {
  return GetEntryHistory(ref.watch(healthRepositoryProvider));
});

/// Manages the state of health entries with async loading.
final healthEntriesNotifierProvider =
    AsyncNotifierProvider<HealthEntriesNotifier, List<HealthEntry>>(
      HealthEntriesNotifier.new,
    );

/// Notifier that manages loading, creating, updating, and deleting health entries.
class HealthEntriesNotifier extends AsyncNotifier<List<HealthEntry>> {
  @override
  Future<List<HealthEntry>> build() async {
    return ref.read(getHealthEntriesProvider).call();
  }

  /// Refreshes the list of health entries from the server.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  /// Creates a new health entry and refreshes the list.
  Future<void> create(HealthEntry entry) async {
    await ref.read(createHealthEntryProvider).call(entry);
    await refresh();
  }

  /// Updates an existing health entry and refreshes the list.
  Future<void> updateEntry(HealthEntry entry) async {
    await ref.read(updateHealthEntryProvider).call(entry);
    await refresh();
  }

  /// Deletes a health entry by [id] and refreshes the list.
  Future<void> delete(String id) async {
    await ref.read(deleteHealthEntryProvider).call(id);
    await refresh();
  }

  /// Marks a health entry as taken and refreshes the list.
  Future<void> markTaken(
    String id, {
    String notes = '',
    DateTime? completedOn,
  }) async {
    await ref
        .read(markEntryTakenProvider)
        .call(id, notes: notes, completedOn: completedOn);
    await refresh();
  }

  Future<void> undoComplete(String id) async {
    await ref.read(healthRepositoryProvider).undoComplete(id);
    await refresh();
  }

  /// Closes an event (status completed, repeat end yesterday).
  Future<void> closeEvent(String id) async {
    await ref.read(healthRepositoryProvider).closeEvent(id);
    await refresh();
  }

  /// Reopens a closed event (clears repeat end and next due date).
  Future<void> reopenEvent(String id) async {
    await ref.read(healthRepositoryProvider).reopenEvent(id);
    await refresh();
  }

  /// Marks an occurrence as skipped without advancing the series.
  Future<HealthHistoryEntry> skipIteration(
    String id, {
    required DateTime dueDate,
    String notes = '',
  }) async {
    final history = await ref
        .read(healthRepositoryProvider)
        .skipIteration(id, dueDate: dueDate, notes: notes);
    await refresh();
    return history;
  }

  /// Reverses a skipped occurrence.
  Future<void> unskipIteration(String id, {required String historyId}) async {
    await ref
        .read(healthRepositoryProvider)
        .unskipIteration(id, historyId: historyId);
    await refresh();
  }

  /// Unmarks the last completed occurrence.
  Future<void> unmarkDone(String id) async {
    await ref.read(healthRepositoryProvider).unmarkDone(id);
    await refresh();
  }

  /// Snoozes a health entry by pushing its next due date forward by [days] from now.
  Future<void> snooze(String id, int days) async {
    final entries = state.valueOrNull ?? [];
    final entry = entries.where((e) => e.id == id).firstOrNull;
    if (entry == null || entry.nextDueDate == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final newDueDate = today.add(Duration(days: days));
    final updated = entry.copyWith(nextDueDate: newDueDate);
    await ref.read(updateHealthEntryProvider).call(updated);
    await refresh();
  }
}

/// Provides filtered entries by type.
final filteredHealthEntriesProvider =
    Provider.family<AsyncValue<List<HealthEntry>>, HealthEntryType?>((
      ref,
      type,
    ) {
      final entriesAsync = ref.watch(healthEntriesNotifierProvider);
      return entriesAsync.whenData((entries) {
        if (type == null) return entries;
        return entries.where((e) => e.type == type).toList();
      });
    });

/// Provides health entries filtered by a specific pet.
final petHealthEntriesProvider =
    FutureProvider.family<List<HealthEntry>, String>((ref, petId) {
      return ref.read(getHealthEntriesProvider).call(petId: petId);
    });

/// Health entries for a specific pet, derived reactively from the global list
/// ([healthEntriesNotifierProvider]) so it reflects creates/edits/deletes and
/// mark-taken without a separate fetch.
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
  if (entry.isCompleted || entry.nextDueDate == null) return false;
  if (entry.isOverdue || entry.isDueToday) return true;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(
    entry.nextDueDate!.year,
    entry.nextDueDate!.month,
    entry.nextDueDate!.day,
  );
  final daysUntilDue = dueDay.difference(today).inDays;
  return daysUntilDue > 0 && daysUntilDue <= entry.remindDaysBefore;
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
