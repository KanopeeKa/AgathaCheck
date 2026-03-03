import '../entities/health_entry.dart';
import '../entities/health_history_entry.dart';

/// Abstract repository for health tracking operations.
///
/// Defines the contract for data access that the domain layer
/// depends on, following the dependency inversion principle.
abstract class HealthRepository {
  /// Retrieves all health entries, optionally filtered by [petId] and [type].
  Future<List<HealthEntry>> getEntries({String? petId, HealthEntryType? type});

  /// Retrieves a single health entry by [id].
  Future<HealthEntry?> getEntry(String id);

  /// Creates a new health entry.
  Future<HealthEntry> createEntry(HealthEntry entry);

  /// Updates an existing health entry.
  Future<HealthEntry> updateEntry(HealthEntry entry);

  /// Deletes a health entry by [id].
  Future<void> deleteEntry(String id);

  /// Marks a health entry as taken and advances the next due date.
  Future<HealthEntry> markTaken(String id, {String notes});

  Future<HealthEntry> undoComplete(String id);

  /// Retrieves the history of administrations for a health entry.
  Future<List<HealthHistoryEntry>> getHistory(String entryId);

  /// Exports all health entries as CSV data.
  Future<String> exportCsv({String? petId});
}
