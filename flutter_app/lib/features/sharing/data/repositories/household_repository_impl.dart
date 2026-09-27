import '../../domain/entities/household_summary.dart';
import '../../domain/repositories/household_repository.dart';
import '../datasources/household_remote_datasource.dart';

class HouseholdRepositoryImpl implements HouseholdRepository {
  HouseholdRepositoryImpl(this._dataSource);

  final HouseholdRemoteDataSource _dataSource;

  @override
  Future<List<HouseholdSummary>> listHouseholds(String token) {
    return _dataSource.listHouseholds(token);
  }

  @override
  Future<HouseholdSummary> createHousehold(
    String name, {
    required String token,
  }) {
    return _dataSource.createHousehold(name, token);
  }
}
