import '../../domain/entities/away_plan_readiness.dart';
import '../../domain/entities/care_period_coverage.dart';
import '../../domain/entities/planned_absence.dart';
import '../../domain/repositories/care_context_repository.dart';
import '../datasources/care_context_remote_datasource.dart';

class CareContextRepositoryImpl implements CareContextRepository {
  CareContextRepositoryImpl(this._remote);

  final CareContextRemoteDataSource _remote;

  @override
  Future<CarePeriodCoverageResult> getCarePeriodCoverage({
    required String petId,
    required String startsOn,
    required String endsOn,
  }) {
    return _remote.fetchCarePeriodCoverage(
      petId: petId,
      startsOn: startsOn,
      endsOn: endsOn,
    );
  }

  @override
  Future<CreatePlannedAbsenceResult> createPlannedAbsence({
    required String startsOn,
    required String endsOn,
    required List<String> petIds,
  }) {
    return _remote.createPlannedAbsence(
      startsOn: startsOn,
      endsOn: endsOn,
      petIds: petIds,
    );
  }

  @override
  Future<List<PlannedAbsence>> listPlannedAbsences({String scope = 'all'}) {
    return _remote.listPlannedAbsences(scope: scope);
  }

  @override
  Future<PlannedAbsence> getPlannedAbsence(String absenceId) {
    return _remote.fetchPlannedAbsence(absenceId);
  }

  @override
  Future<AwayPlanReadiness> getAwayPlanReadiness(String absenceId) =>
      _remote.fetchAwayPlanReadiness(absenceId);

  @override
  Future<PlannedAbsence> updateHandoverNote({
    required String absenceId,
    String? handoverNote,
  }) => _remote.updateHandoverNote(
    absenceId: absenceId,
    handoverNote: handoverNote,
  );

  @override
  Future<void> recordHandoverDownload(String absenceId) =>
      _remote.recordHandoverDownload(absenceId);
}
