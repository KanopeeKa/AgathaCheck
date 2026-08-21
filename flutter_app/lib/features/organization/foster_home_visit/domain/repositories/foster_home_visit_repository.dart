import '../entities/foster_home_visit.dart';

abstract class FosterHomeVisitRepository {
  Future<List<FosterHomeVisit>> loadVisits(
    String orgId,
    String fosterParentId,
    String token,
  );

  Future<FosterHomeVisitStatusSnapshot> loadStatus(
    String orgId,
    String fosterParentId,
    String token,
  );

  Future<FosterHomeVisit> scheduleVisit(
    String orgId,
    String fosterParentId, {
    required String visitDate,
    required String visitTime,
    String address = '',
    String notes = '',
    required String token,
  });

  Future<FosterHomeVisit> rescheduleVisit(
    String orgId,
    String visitId, {
    required String visitDate,
    required String visitTime,
    String? address,
    String? notes,
    required String token,
  });

  Future<FosterHomeVisit> cancelVisit(
    String orgId,
    String visitId, {
    String cancelReason = '',
    required String token,
  });

  Future<FosterHomeVisit> validateVisit(
    String orgId,
    String visitId, {
    required String outcome,
    String outcomeReason = '',
    required String token,
  });
}
