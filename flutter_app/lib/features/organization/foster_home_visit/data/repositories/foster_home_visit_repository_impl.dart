import '../../domain/entities/foster_home_visit.dart';
import '../../domain/repositories/foster_home_visit_repository.dart';
import '../datasources/foster_home_visit_remote.dart';

class FosterHomeVisitRepositoryImpl implements FosterHomeVisitRepository {
  FosterHomeVisitRepositoryImpl(this._remote);

  final FosterHomeVisitRemote _remote;

  @override
  Future<List<FosterHomeVisit>> loadVisits(
    String orgId,
    String fosterParentId,
    String token,
  ) async {
    final row = await _remote.loadVisits(orgId, fosterParentId, token);
    final visits = row['visits'];
    if (visits is! List) return const [];
    return visits
        .whereType<Map>()
        .map((item) => FosterHomeVisit.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<FosterHomeVisitStatusSnapshot> loadStatus(
    String orgId,
    String fosterParentId,
    String token,
  ) async {
    final row = await _remote.loadStatus(orgId, fosterParentId, token);
    return FosterHomeVisitStatusSnapshot.fromJson(row);
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
    final row = await _remote.scheduleVisit(
      orgId,
      fosterParentId,
      visitDate: visitDate,
      visitTime: visitTime,
      address: address,
      notes: notes,
      token: token,
    );
    return FosterHomeVisit.fromJson(row);
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
    final row = await _remote.rescheduleVisit(
      orgId,
      visitId,
      visitDate: visitDate,
      visitTime: visitTime,
      address: address,
      notes: notes,
      token: token,
    );
    return FosterHomeVisit.fromJson(row);
  }

  @override
  Future<FosterHomeVisit> cancelVisit(
    String orgId,
    String visitId, {
    String cancelReason = '',
    required String token,
  }) async {
    final row = await _remote.cancelVisit(
      orgId,
      visitId,
      cancelReason: cancelReason,
      token: token,
    );
    return FosterHomeVisit.fromJson(row);
  }

  @override
  Future<FosterHomeVisit> validateVisit(
    String orgId,
    String visitId, {
    required String outcome,
    String outcomeReason = '',
    required String token,
  }) async {
    final row = await _remote.validateVisit(
      orgId,
      visitId,
      outcome: outcome,
      outcomeReason: outcomeReason,
      token: token,
    );
    return FosterHomeVisit.fromJson(row);
  }
}
