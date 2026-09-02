import '../entities/health_entry.dart';
import '../entities/health_history_entry.dart';
import '../entities/health_occurrence.dart';

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
  Future<HealthEntry> markTaken(
    String id, {
    String notes = '',
    DateTime? completedOn,
  });

  Future<HealthEntry> undoComplete(String id);

  /// Closes an event series (status completed, repeat end yesterday).
  Future<HealthEntry> closeEvent(String id);

  /// Reopens a closed event (clears repeat end and next due date).
  Future<HealthEntry> reopenEvent(String id);

  /// Marks an occurrence as skipped without advancing the series.
  Future<HealthHistoryEntry> skipIteration(
    String id, {
    required DateTime dueDate,
    String notes = '',
  });

  /// Reverses a skipped occurrence.
  Future<void> unskipIteration(String id, {required String historyId});

  /// Unmarks the last completed occurrence (alias for undoComplete).
  Future<HealthEntry> unmarkDone(String id);

  /// Retrieves the history of administrations for a health entry.
  Future<List<HealthHistoryEntry>> getHistory(String entryId);

  /// Exports all health entries as CSV data.
  Future<String> exportCsv({String? petId});

  Future<List<HealthOccurrence>> getOpenOccurrences(String entryId);

  Future<List<HealthOccurrence>> getPastOccurrences(String entryId);

  Future<HealthOccurrence> completeOccurrence(
    String entryId,
    String occurrenceId, {
    String notes = '',
    DateTime? completedOn,
    bool skipEarlierMissed = false,
  });

  Future<HealthOccurrence> skipOccurrence(
    String entryId,
    String occurrenceId, {
    String notes = '',
  });

  Future<int> skipMissedOccurrences(String entryId);

  Future<HealthOccurrence> undoOccurrence(
    String entryId,
    String occurrenceId,
  );
}
