import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_history_entry.dart';
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
  Future<List<HealthEntry>> getEntries(
      {String? petId, HealthEntryType? type}) {
    // Use the canonical API string, not enum.name (minified in release builds).
    return dataSource.getEntries(
        petId: petId,
        type: type == null ? null : HealthEntryModel.typeToApi(type));
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
  Future<HealthEntry> markTaken(String id, {String notes = '', DateTime? completedOn}) {
    return dataSource.markTaken(id, notes: notes, completedOn: completedOn);
  }

  @override
  Future<HealthEntry> undoComplete(String id) {
    return dataSource.undoComplete(id);
  }

  @override
  Future<List<HealthHistoryEntry>> getHistory(String entryId) {
    return dataSource.getHistory(entryId);
  }

  @override
  Future<String> exportCsv({String? petId}) {
    return dataSource.exportCsv(petId: petId);
  }
}
