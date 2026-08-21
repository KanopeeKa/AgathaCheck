import 'package:pet_profile_app/features/organization/foster_home_visit/domain/entities/foster_home_visit.dart';
import 'package:pet_profile_app/features/organization/foster_home_visit/domain/repositories/foster_home_visit_repository.dart';

class FakeFosterHomeVisitRepository implements FosterHomeVisitRepository {
  FakeFosterHomeVisitRepository({
    this.visits = const [],
    this.status = const FosterHomeVisitStatusSnapshot(),
  });

  List<FosterHomeVisit> visits;
  FosterHomeVisitStatusSnapshot status;

  @override
  Future<List<FosterHomeVisit>> loadVisits(
    String orgId,
    String fosterParentId,
    String token,
  ) async {
    return visits;
  }

  @override
  Future<FosterHomeVisitStatusSnapshot> loadStatus(
    String orgId,
    String fosterParentId,
    String token,
  ) async {
    return status;
  }

  @override
  Future<FosterHomeVisit> scheduleVisit(
    String orgId,
    String fosterParentId, {
    required String visitDate,
    required String visitTime,
    String address = '',
    String notes = '',
    required String token,
  }) async {
    final visit = FosterHomeVisit(
      id: 'hv-new',
      organizationId: orgId,
      orgFosterParentId: fosterParentId,
      status: FosterHomeVisitStatus.scheduled,
      visitDate: visitDate,
      visitTime: visitTime,
      address: address,
      notes: notes,
    );
    visits = [visit, ...visits];
    return visit;
  }

  @override
  Future<FosterHomeVisit> rescheduleVisit(
    String orgId,
    String visitId, {
    required String visitDate,
    required String visitTime,
    String? address,
    String? notes,
    required String token,
  }) async {
    visits = visits
        .map(
          (visit) => visit.id == visitId
              ? FosterHomeVisit(
                  id: visit.id,
                  organizationId: visit.organizationId,
                  orgFosterParentId: visit.orgFosterParentId,
                  status: visit.status,
                  visitDate: visitDate,
                  visitTime: visitTime,
                  address: address ?? visit.address,
                  notes: notes ?? visit.notes,
                )
              : visit,
        )
        .toList();
    return visits.firstWhere((visit) => visit.id == visitId);
  }

  @override
  Future<FosterHomeVisit> cancelVisit(
    String orgId,
    String visitId, {
    String cancelReason = '',
    required String token,
  }) async {
    visits = visits
        .map(
          (visit) => visit.id == visitId
              ? FosterHomeVisit(
                  id: visit.id,
                  organizationId: visit.organizationId,
                  orgFosterParentId: visit.orgFosterParentId,
                  status: FosterHomeVisitStatus.cancelled,
                  visitDate: visit.visitDate,
                  visitTime: visit.visitTime,
                  cancelReason: cancelReason,
                )
              : visit,
        )
        .toList();
    return visits.firstWhere((visit) => visit.id == visitId);
  }

  @override
  Future<FosterHomeVisit> validateVisit(
    String orgId,
    String visitId, {
    required String outcome,
    String outcomeReason = '',
    required String token,
  }) async {
    visits = visits
        .map(
          (visit) => visit.id == visitId
              ? FosterHomeVisit(
                  id: visit.id,
                  organizationId: visit.organizationId,
                  orgFosterParentId: visit.orgFosterParentId,
                  status: FosterHomeVisitStatus.validated,
                  visitDate: visit.visitDate,
                  visitTime: visit.visitTime,
                  outcome: FosterHomeVisitOutcome.fromWire(outcome),
                  outcomeReason: outcomeReason,
                )
              : visit,
        )
        .toList();
    return visits.firstWhere((visit) => visit.id == visitId);
  }
}
