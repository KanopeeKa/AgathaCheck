import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_history_entry.dart';
import '../../domain/entities/health_occurrence.dart';
import '../../domain/entities/reschedule_occurrence_result.dart';
import '../../domain/repositories/health_repository.dart';
import '../datasources/health_remote_datasource.dart';
import '../models/health_entry_model.dart';

/// Implementation of [HealthRepository] backed by a remote data source.
class HealthRepositoryImpl implements HealthRepository {
  /// Creates a [HealthRepositoryImpl] with the given [dataSource].
  const HealthRepositoryImpl(this.dataSource);

  /// The remote data source for health entries.
  final HealthRemoteDataSource dataSource;

  @override
  Future<List<HealthEntry>> getEntries({String? petId, HealthEntryType? type}) {
    return dataSource.getEntries(
      petId: petId,
      type: type == null ? null : HealthEntryModel.typeToApi(type),
    );
  }

  @override
  Future<HealthEntry?> getEntry(String id) {
    return dataSource.getEntry(id);
  }

  @override
  Future<HealthEntry> createEntry(HealthEntry entry) {
    return dataSource.createEntry(HealthEntryModel.fromEntity(entry));
  }

  @override
  Future<HealthEntry> updateEntry(HealthEntry entry) {
    return dataSource.updateEntry(HealthEntryModel.fromEntity(entry));
  }

  @override
  Future<void> deleteEntry(String id) {
    return dataSource.deleteEntry(id);
  }

  @override
  Future<HealthEntry> closeEvent(String id) {
    return dataSource.closeEvent(id);
  }

  @override
  Future<HealthEntry> reopenEvent(String id) {
    return dataSource.reopenEvent(id);
  }

  @override
  Future<HealthEntry> pauseCareItem(String id, {DateTime? until}) {
    return dataSource.pauseCareItem(id, until: until);
  }

  @override
  Future<HealthEntry> resumeCareItem(String id, {DateTime? resumeOn}) {
    return dataSource.resumeCareItem(id, resumeOn: resumeOn);
  }

  @override
  Future<HealthEntry> unmarkDone(String id) {
    return dataSource.unmarkDone(id);
  }

  @override
  Future<List<HealthHistoryEntry>> getHistory(String entryId) {
    return dataSource.getHistory(entryId);
  }

  @override
  Future<String> exportCsv({String? petId}) {
    return dataSource.exportCsv(petId: petId);
  }

  @override
  Future<List<HealthOccurrence>> getOpenOccurrences(String entryId) {
    return dataSource.getOpenOccurrences(entryId);
  }

  @override
  Future<List<HealthOccurrence>> getPastOccurrences(String entryId) {
    return dataSource.getPastOccurrences(entryId);
  }

  @override
  Future<HealthOccurrence> completeOccurrence(
    String entryId,
    String occurrenceId, {
    String notes = '',
    DateTime? completedOn,
    bool skipEarlierMissed = false,
  }) {
    return dataSource.completeOccurrence(
      entryId,
      occurrenceId,
      notes: notes,
      completedOn: completedOn,
      skipEarlierMissed: skipEarlierMissed,
    );
  }

  @override
  Future<HealthOccurrence> skipOccurrence(
    String entryId,
    String occurrenceId, {
    String notes = '',
  }) {
    return dataSource.skipOccurrence(entryId, occurrenceId, notes: notes);
  }

  @override
  Future<int> skipMissedOccurrences(String entryId) {
    return dataSource.skipMissedOccurrences(entryId);
  }

  @override
  Future<HealthOccurrence> undoOccurrence(String entryId, String occurrenceId) {
    return dataSource.undoOccurrence(entryId, occurrenceId);
  }

  @override
  Future<HealthOccurrence> updateOccurrenceNotes(
    String entryId,
    String occurrenceId,
    String notes, {
    String? providerContactId,
    String? providerTypedName,
  }) {
    return dataSource.updateOccurrenceNotes(
      entryId,
      occurrenceId,
      notes,
      providerContactId: providerContactId,
      providerTypedName: providerTypedName,
    );
  }

  @override
  Future<RescheduleOccurrenceResult> rescheduleOccurrence(
    String entryId,
    String occurrenceId,
    DateTime scheduledDate, {
    String? reasonCode,
  }) async {
    final result = await dataSource.rescheduleOccurrence(
      entryId,
      occurrenceId,
      scheduledDate,
      reasonCode: reasonCode,
    );
    return RescheduleOccurrenceResult(
      occurrence: result.occurrence,
      warnings: result.warnings,
      nextDueDate: result.nextDueDate,
    );
  }
}
