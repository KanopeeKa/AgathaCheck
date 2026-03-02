import '../../domain/entities/weight_entry.dart';
import '../../domain/repositories/weight_repository.dart';
import '../datasources/weight_remote_datasource.dart';
import '../models/weight_entry_model.dart';

class WeightRepositoryImpl implements WeightRepository {
  WeightRepositoryImpl(this._dataSource);

  final WeightRemoteDataSource _dataSource;

  @override
  Future<List<WeightEntry>> getEntries(String petId) {
    return _dataSource.getEntries(petId);
  }

  @override
  Future<WeightEntry> createEntry(WeightEntry entry) {
    return _dataSource.createEntry(WeightEntryModel.fromEntity(entry));
  }

  @override
  Future<WeightEntry> updateEntry(WeightEntry entry) {
    return _dataSource.updateEntry(WeightEntryModel.fromEntity(entry));
  }

  @override
  Future<void> deleteEntry(int id) {
    return _dataSource.deleteEntry(id);
  }

  @override
  Future<WeightEntry?> getLatestWeight(String petId) {
    return _dataSource.getLatestWeight(petId);
  }
}
