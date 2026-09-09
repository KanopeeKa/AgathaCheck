import '../../domain/entities/care_recommendation.dart';
import '../../domain/entities/care_safeguard.dart';
import '../../domain/repositories/care_intelligence_repository.dart';
import '../datasources/care_intelligence_remote_datasource.dart';

class CareIntelligenceRepositoryImpl implements CareIntelligenceRepository {
  const CareIntelligenceRepositoryImpl(this._dataSource);

  final CareIntelligenceRemoteDataSource _dataSource;

  @override
  Future<List<CareRecommendation>> getRecommendations(String petId) async {
    final models = await _dataSource.fetchRecommendations(petId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<CareSafeguard>> getSafeguards(String petId) async {
    final models = await _dataSource.fetchSafeguards(petId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<CareSafeguard> dismissSafeguard({
    required String petId,
    required String safeguardId,
  }) async {
    final model = await _dataSource.dismissSafeguard(
      petId: petId,
      safeguardId: safeguardId,
    );
    return model.toEntity();
  }

  @override
  Future<CareRecommendation> respond({
    required String petId,
    required String recommendationId,
    required CareRecommendationResponseAction action,
    Map<String, dynamic>? adjust,
  }) async {
    final model = await _dataSource.respond(
      petId: petId,
      recommendationId: recommendationId,
      action: action,
      adjust: adjust,
    );
    return model.toEntity();
  }
}
