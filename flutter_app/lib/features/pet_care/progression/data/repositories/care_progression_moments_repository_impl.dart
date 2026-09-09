import '../../domain/entities/care_pending_moment.dart';
import '../../domain/repositories/care_progression_moments_repository.dart';
import '../datasources/care_progression_moments_remote_datasource.dart';

class CareProgressionMomentsRepositoryImpl
    implements CareProgressionMomentsRepository {
  const CareProgressionMomentsRepositoryImpl(this._dataSource);

  final CareProgressionMomentsRemoteDataSource _dataSource;

  @override
  Future<CarePendingMomentsResponse> getPendingMoments(String petId) async {
    final model = await _dataSource.fetchPendingMoments(petId);
    return model.toEntity();
  }

  @override
  Future<void> acknowledgePresented({
    required String petId,
    required String bundleId,
  }) async {
    await _dataSource.acknowledgePresented(petId: petId, bundleId: bundleId);
  }
}
