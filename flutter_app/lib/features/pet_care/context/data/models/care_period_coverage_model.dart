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

  static CarePeriodRoutineItem routineItemFromJson(Map<String, dynamic> raw) {
    return CarePeriodRoutineItem(
      healthEntryId: raw['health_entry_id'] as String? ?? '',
      name: raw['name'] as String? ?? '',
      type: raw['type'] as String? ?? '',
      careFamily: raw['care_family'] as String? ?? '',
      scheduledTime: raw['scheduled_time'] as String?,
      certainty: raw['certainty'] as String? ?? 'complete',
      occurrenceCount: raw['occurrence_count'] as int? ?? 0,
      status: raw['status'] as String? ?? 'pending',
      firstScheduledDate: raw['first_scheduled_date'] as String? ?? '',
      lastScheduledDate: raw['last_scheduled_date'] as String? ?? '',
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
    final routineItemsJson =
        json['routine_items'] as List<dynamic>? ?? const [];
    final datedItemsJson = json['dated_items'] as List<dynamic>? ?? const [];
    final uncertaintiesJson =
        json['uncertainties'] as List<dynamic>? ?? const [];

    final items = itemsJson
        .map((raw) => projectionItemFromJson(raw as Map<String, dynamic>))
        .toList(growable: false);
    final routineItems = routineItemsJson
        .map((raw) => routineItemFromJson(raw as Map<String, dynamic>))
        .toList(growable: false);
    final datedItems = datedItemsJson.isNotEmpty
        ? datedItemsJson
              .map((raw) => projectionItemFromJson(raw as Map<String, dynamic>))
              .toList(growable: false)
        : items;

    return CarePeriodCoverageResult(
      startsOn: json['starts_on'] as String? ?? '',
      endsOn: json['ends_on'] as String? ?? '',
      projectionStatus: projectionStatus,
      uncertainties: uncertaintiesJson
          .map((raw) {
            final map = raw as Map<String, dynamic>;
            return CarePeriodUncertainty(
              healthEntryId: map['health_entry_id'] as String? ?? '',
              reason: map['reason'] as String? ?? '',
              name: map['name'] as String? ?? '',
              type: map['type'] as String?,
              careFamily: map['care_family'] as String?,
            );
          })
          .toList(growable: false),
      items: items,
      routineItems: routineItems,
      datedItems: datedItems,
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
