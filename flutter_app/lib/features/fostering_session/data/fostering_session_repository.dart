import '../../organization/data/datasources/organization_remote_datasource.dart';
import '../domain/entities/fostering_session_detail.dart';

typedef FosteringSessionDetailLoader =
    Future<Map<String, dynamic>> Function(
      String orgId,
      String placementId,
      String token,
    );

class FosteringSessionRepository {
  FosteringSessionRepository(this._loadRow);

  final FosteringSessionDetailLoader _loadRow;

  factory FosteringSessionRepository.fromDataSource(
    OrganizationRemoteDataSource dataSource,
  ) {
    return FosteringSessionRepository(
      (orgId, placementId, token) =>
          dataSource.getPlacementDetail(orgId, placementId, token),
    );
  }

  Future<FosteringSessionDetail> getSessionDetail(
    String orgId,
    String placementId,
    String token,
  ) async {
    final row = await _loadRow(orgId, placementId, token);
    return FosteringSessionDetail.fromJson(row);
  }
}
