import '../../domain/entities/care_establishment.dart';
import '../../domain/repositories/care_progression_repository.dart';
import '../datasources/care_progression_remote_datasource.dart';

class CareProgressionRepositoryImpl implements CareProgressionRepository {
  const CareProgressionRepositoryImpl(this._dataSource);

  final CareProgressionRemoteDataSource _dataSource;

  @override
  Future<List<CareEstablishment>> getEstablishments(String petId) async {
    final models = await _dataSource.fetchEstablishments(petId);
    return models.map((m) => m.toEntity()).toList();
  }
}
