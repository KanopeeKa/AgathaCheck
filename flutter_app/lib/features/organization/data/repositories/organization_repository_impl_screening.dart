import '../../domain/repositories/organization_repository.dart';
import 'organization_repository_impl_base.dart';

mixin OrganizationRepositoryScreeningMixin on OrganizationRepositoryImplBase {
  @override
  Future<List<Map<String, dynamic>>> getProspects(String orgId, String token) =>
      dataSource.getProspects(orgId, token);

  @override
  Future<List<Map<String, dynamic>>> getAdoptionVisits(
    String orgId,
    String token,
  ) => dataSource.getAdoptionVisits(orgId, token);

  @override
  Future<Map<String, dynamic>> getAdoptionJourney(
    String orgId,
    String placementId,
    String token,
  ) => dataSource.getAdoptionJourney(orgId, placementId, token);

  @override
  Future<Map<String, dynamic>> getSessionChecklist(
    String orgId,
    String placementId,
    String token,
  ) => dataSource.getSessionChecklist(orgId, placementId, token);
}
