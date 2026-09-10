import '../../domain/entities/care_period_coverage.dart';

class CarePeriodCoverageModel {
  static CarePeriodCoverageResult fromJson(Map<String, dynamic> json) {
    final coverageJson = json['coverage'] as Map<String, dynamic>? ?? {};
    final coverageState =
        CarePeriodCoverageState.fromWire(coverageJson['coverage_state'] as String?) ??
        CarePeriodCoverageState.indeterminate;
    final projectionStatus =
        CarePeriodProjectionStatus.fromWire(json['projection_status'] as String?) ??
        CarePeriodProjectionStatus.partiallyIndeterminate;

    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    final uncertaintiesJson = json['uncertainties'] as List<dynamic>? ?? const [];

    return CarePeriodCoverageResult(
      startsOn: json['starts_on'] as String? ?? '',
      endsOn: json['ends_on'] as String? ?? '',
      projectionStatus: projectionStatus,
      uncertainties: uncertaintiesJson
          .map(
            (raw) => CarePeriodUncertainty(
              healthEntryId: (raw as Map<String, dynamic>)['health_entry_id']
                  as String? ??
                  '',
              reason: raw['reason'] as String? ?? '',
            ),
          )
          .toList(growable: false),
      items: itemsJson
          .map(
            (raw) => CarePeriodProjectionItem(
              healthEntryId: (raw as Map<String, dynamic>)['health_entry_id']
                  as String? ??
                  '',
              occurrenceId: raw['occurrence_id'] as String?,
              scheduledDate: raw['scheduled_date'] as String? ?? '',
              scheduledTime: raw['scheduled_time'] as String?,
              status: raw['status'] as String? ?? 'pending',
              source: raw['source'] as String? ?? 'projected',
              name: raw['name'] as String? ?? '',
              type: raw['type'] as String? ?? '',
              careFamily: raw['care_family'] as String? ?? '',
            ),
          )
          .toList(growable: false),
      coverage: CarePeriodCoverageSummary(
        policyVersion: coverageJson['policy_version'] as String? ?? '1',
        coverageState: coverageState,
        reasonCodes: (coverageJson['reason_codes'] as List<dynamic>? ?? const [])
            .map((code) => code.toString())
            .toList(growable: false),
        reassuranceAvailable: coverageJson['reassurance_available'] == true,
      ),
    );
  }
}
