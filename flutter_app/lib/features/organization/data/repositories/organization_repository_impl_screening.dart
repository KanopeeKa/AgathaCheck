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

  @override
  Future<Map<String, dynamic>> updateSessionChecklistItem(
    String orgId,
    String placementId,
    String itemKey, {
    required bool completed,
    required String token,
  }) => dataSource.updateSessionChecklistItem(
    orgId,
    placementId,
    itemKey,
    completed: completed,
    token: token,
  );

  @override
  Future<Map<String, dynamic>> getAdoptionMilestones(
    String orgId,
    String placementId,
    String token,
  ) => dataSource.getAdoptionMilestones(orgId, placementId, token);

  @override
  Future<Map<String, dynamic>> updateAdoptionMilestoneItem(
    String orgId,
    String journeyId,
    String itemKey, {
    required bool completed,
    required String token,
  }) => dataSource.updateAdoptionMilestoneItem(
    orgId,
    journeyId,
    itemKey,
    completed: completed,
    token: token,
  );

  @override
  Future<Map<String, dynamic>> getRegisterExport(
    String orgId,
    String placementId,
    String token,
  ) => dataSource.getRegisterExport(orgId, placementId, token);

  @override
  Future<Map<String, dynamic>> recordAdoptionVisitOutcome(
    String orgId,
    String visitId,
    String visitOutcome,
    String token,
  ) => dataSource.recordAdoptionVisitOutcome(
    orgId,
    visitId,
    visitOutcome,
    token,
  );

  @override
  Future<Map<String, dynamic>> completeVisitAndStartAdoption(
    String orgId,
    String placementId, {
    String? visitId,
    String adoptionConditions = '',
    required String token,
  }) => dataSource.completeVisitAndStartAdoption(
    orgId,
    placementId,
    visitId: visitId,
    adoptionConditions: adoptionConditions,
    token: token,
  );
}
