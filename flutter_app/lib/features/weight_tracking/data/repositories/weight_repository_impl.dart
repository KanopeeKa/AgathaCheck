import '../../domain/entities/weight_entry.dart';
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
  Future<WeightEntry> createEntry(WeightEntry entry, String token) {
    return _dataSource.createEntry(WeightEntryModel.fromEntity(entry), token);
  }

  @override
  Future<WeightEntry> updateEntry(WeightEntry entry, String token) {
    return _dataSource.updateEntry(WeightEntryModel.fromEntity(entry), token);
  }

  @override
  Future<void> deleteEntry(String id, String token) {
    return _dataSource.deleteEntry(id, token);
  }

  @override
  Future<WeightEntry?> getLatestWeight(String petId, String token) {
    return _dataSource.getLatestWeight(petId, token);
  }
}
