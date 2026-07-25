import '../../../../core/utils/calendar_date.dart';
import '../../domain/entities/foster_request.dart';
import 'organization_repository_impl_base.dart';

mixin OrganizationRepositoryFosterRequestsMixin
    on OrganizationRepositoryImplBase {
  @override
  Future<List<String>> getEligibleFosterTargetIds(
    String orgId, {
    required List<String> petIds,
    required String token,
  }) async {
    final rows = await dataSource.getEligibleFosterTargets(
      orgId,
      petIds: petIds,
      token: token,
    );
    return rows
        .map((row) => row['org_foster_parent_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<List<FosterRequest>> getFosterRequests(
    String orgId,
    String token,
  ) async {
    final rows = await dataSource.getFosterRequests(orgId, token);
    return rows.map(FosterRequest.fromJson).toList();
  }

  @override
  Future<FosterRequest> createFosterRequest(
    String orgId, {
    required String message,
    required List<String> petIds,
    required List<String> orgFosterParentIds,
    bool send = false,
    required String token,
  }) async {
    final row = await dataSource.createFosterRequest(
      orgId,
      message: message,
      petIds: petIds,
      orgFosterParentIds: orgFosterParentIds,
      send: send,
      token: token,
    );
    return FosterRequest.fromJson(row);
  }

  @override
  Future<FosterRequest> getFosterRequestDetail(
    String orgId,
    String requestId,
    String token,
  ) async {
    final row = await dataSource.getFosterRequestDetail(
      orgId,
      requestId,
      token,
    );
    return FosterRequest.fromJson(row);
  }

  @override
  Future<FosterRequest> sendFosterRequest(
    String orgId,
    String requestId, {
    required String token,
  }) async {
    final row = await dataSource.sendFosterRequest(orgId, requestId, token);
    return FosterRequest.fromJson(row);
  }

  @override
  Future<FosterRequest> respondToFosterRequest(
    String orgId,
    String requestId, {
    required FosterResponseType response,
    String? message,
    DateTime? earliestAvailability,
    required String token,
  }) async {
    final row = await dataSource.respondToFosterRequest(
      orgId,
      requestId,
      response: response.toWire(),
      message: message,
      earliestAvailability: earliestAvailability != null
          ? toCalendarDateString(earliestAvailability)
          : null,
      token: token,
    );
    return FosterRequest.fromJson(row);
  }
}
