import '../../domain/entities/care_period_coverage.dart';

class CarePeriodCoverageModel {
  static CarePeriodProjectionItem projectionItemFromJson(
    Map<String, dynamic> raw,
  ) {
    return CarePeriodProjectionItem(
      healthEntryId: raw['health_entry_id'] as String? ?? '',
      occurrenceId: raw['occurrence_id'] as String?,
      scheduledDate: raw['scheduled_date'] as String? ?? '',
      scheduledTime: raw['scheduled_time'] as String?,
      status: raw['status'] as String? ?? 'pending',
      source: raw['source'] as String? ?? 'projected',
      name: raw['name'] as String? ?? '',
      type: raw['type'] as String? ?? '',
      careFamily: raw['care_family'] as String? ?? '',
    );
  }

  static PlannedCareItem plannedCareItemFromJson(Map<String, dynamic> raw) {
    final kind =
        PlannedCareKind.fromWire(raw['kind'] as String?) ??
        PlannedCareKind.singleOnce;
    final timesOfDay =
        (raw['times_of_day'] as List<dynamic>? ?? const [])
            .map((value) => value.toString())
            .toList(growable: false);

    return PlannedCareItem(
      kind: kind,
      healthEntryId: raw['health_entry_id'] as String? ?? '',
      name: raw['name'] as String? ?? '',
      type: raw['type'] as String?,
      careFamily: raw['care_family'] as String?,
      frequency: raw['frequency'] as String?,
      frequencyInterval: raw['frequency_interval'] as int? ?? 1,
      timesOfDay: timesOfDay,
      nextDueDate: raw['next_due_date'] as String?,
      certainty: raw['certainty'] as String?,
      reason: raw['reason'] as String?,
      occurrenceId: raw['occurrence_id'] as String?,
      scheduledDate: raw['scheduled_date'] as String?,
      status: raw['status'] as String?,
      firstScheduledDate: raw['first_scheduled_date'] as String?,
      lastScheduledDate: raw['last_scheduled_date'] as String?,
      occurrenceCount: raw['occurrence_count'] as int? ?? 0,
    );
  }

  static CarePeriodCoverageResult fromJson(Map<String, dynamic> json) {
    final coverageJson = json['coverage'] as Map<String, dynamic>? ?? {};
    final coverageState =
        CarePeriodCoverageState.fromWire(
          coverageJson['coverage_state'] as String?,
        ) ??
        CarePeriodCoverageState.indeterminate;
    final projectionStatus =
        CarePeriodProjectionStatus.fromWire(
          json['projection_status'] as String?,
        ) ??
        CarePeriodProjectionStatus.partiallyIndeterminate;

    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    final plannedCareItemsJson =
        json['planned_care_items'] as List<dynamic>? ?? const [];

    final items = itemsJson
        .map((raw) => projectionItemFromJson(raw as Map<String, dynamic>))
        .toList(growable: false);
    final plannedCareItems = plannedCareItemsJson
        .map((raw) => plannedCareItemFromJson(raw as Map<String, dynamic>))
        .toList(growable: false);

    return CarePeriodCoverageResult(
      startsOn: json['starts_on'] as String? ?? '',
      endsOn: json['ends_on'] as String? ?? '',
      projectionStatus: projectionStatus,
      items: items,
      plannedCareItems: plannedCareItems,
      coverage: CarePeriodCoverageSummary(
        policyVersion: coverageJson['policy_version'] as String? ?? '1',
        coverageState: coverageState,
        reasonCodes:
            (coverageJson['reason_codes'] as List<dynamic>? ?? const [])
                .map((code) => code.toString())
                .toList(growable: false),
        reassuranceAvailable: coverageJson['reassurance_available'] == true,
      ),
    );
  }
}
