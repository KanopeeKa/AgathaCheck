import '../../organization/data/datasources/foster_placements_remote_datasource.dart';
import '../../organization/data/datasources/organization_remote_datasource.dart';
import '../domain/entities/fostering_session_detail.dart';

typedef FosteringSessionDetailLoader =
    Future<Map<String, dynamic>> Function(
      String orgId,
      String placementId,
      String token,
    );

typedef FosterPlacementDetailLoader =
    Future<Map<String, dynamic>> Function(String placementId, String token);

class FosteringSessionRepository {
  FosteringSessionRepository({
    required FosteringSessionDetailLoader loadShelterRow,
    FosterPlacementDetailLoader? loadFosterRow,
  }) : _loadShelterRow = loadShelterRow,
       _loadFosterRow = loadFosterRow;

  final FosteringSessionDetailLoader _loadShelterRow;
  final FosterPlacementDetailLoader? _loadFosterRow;

  factory FosteringSessionRepository.fromDataSource(
    OrganizationRemoteDataSource dataSource,
  ) {
    return FosteringSessionRepository(
      loadShelterRow: (orgId, placementId, token) =>
          dataSource.getPlacementDetail(orgId, placementId, token),
    );
  }

  factory FosteringSessionRepository.fromFosterDataSource(
    FosterPlacementsRemoteDataSource dataSource,
  ) {
    return FosteringSessionRepository(
      loadShelterRow: (_, placementId, token) =>
          dataSource.getPlacementDetail(placementId, token),
      loadFosterRow: (placementId, token) =>
          dataSource.getPlacementDetail(placementId, token),
    );
  }

  Future<FosteringSessionDetail> getSessionDetail(
    String orgId,
    String placementId,
    String token,
  ) async {
    final row = await _loadShelterRow(orgId, placementId, token);
    return FosteringSessionDetail.fromJson(row);
  }

  Future<FosteringSessionDetail> getFosterSessionDetail(
    String placementId,
    String token,
  ) async {
    final loader = _loadFosterRow;
    if (loader == null) {
      throw StateError('Foster session loader not configured');
    }
    final row = await loader(placementId, token);
    return FosteringSessionDetail.fromJson(row);
  }
}
