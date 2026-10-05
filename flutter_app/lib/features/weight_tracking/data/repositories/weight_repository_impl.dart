import '../../domain/entities/weight_entry.dart';
import '../../domain/entities/weight_fulfilment_candidates.dart';
import '../../domain/entities/weight_overview.dart';
import '../../domain/entities/weight_write_outcomes.dart';
import '../../domain/repositories/weight_repository.dart';
import '../datasources/weight_remote_datasource.dart';
import '../models/weight_entry_model.dart';

class WeightRepositoryImpl implements WeightRepository {
  WeightRepositoryImpl(this._dataSource);

  final WeightRemoteDataSource _dataSource;

  @override
  Future<List<WeightEntry>> getEntries(String petId, String token) {
    return _dataSource.getEntries(petId, token);
  }

  @override
  Future<WeightOverview> getOverview(String petId, String token) {
    return _dataSource.getOverview(petId, token);
  }

  @override
  Future<WeightFulfilmentCandidates> getFulfilmentCandidates(
    String petId,
    DateTime date,
    String token,
  ) {
    return _dataSource.getFulfilmentCandidates(petId, date, token);
  }

  @override
  Future<WeightEntry> createEntry(WeightEntry entry, String token) {
    return _dataSource.createEntry(WeightEntryModel.fromEntity(entry), token);
  }

  @override
  Future<WeightSaveOutcome> createEntryWithFulfilment(
    WeightEntry entry,
    String fulfilsOccurrenceId,
    String token,
  ) {
    return _dataSource.createEntryWithFulfilment(
      WeightEntryModel.fromEntity(entry),
      fulfilsOccurrenceId,
      token,
    );
  }

  @override
  Future<WeightSaveOutcome> fulfilEntry(
    String weightEntryId,
    String occurrenceId,
    String token,
  ) {
    return _dataSource.fulfilEntry(weightEntryId, occurrenceId, token);
  }

  @override
  Future<WeightEntry> updateEntry(WeightEntry entry, String token) {
    return _dataSource.updateEntry(WeightEntryModel.fromEntity(entry), token);
  }

  @override
  Future<WeightDeleteOutcome> deleteEntry(String id, String token) {
    return _dataSource.deleteEntry(id, token);
  }

  @override
  Future<WeightEntry?> getLatestWeight(String petId, String token) {
    return _dataSource.getLatestWeight(petId, token);
  }

  @override
  Future<void> scheduleUndo(
    String careEntryId,
    String undoToken,
    String token,
  ) {
    return _dataSource.scheduleUndo(careEntryId, undoToken, token);
  }
}
