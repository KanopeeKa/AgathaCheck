import '../../domain/entities/away_plan_readiness.dart';

class AwayPlanReadinessModel {
  static AwayPlanReadiness fromJson(Map<String, dynamic> json) {
    final carerJson = json['carer_coverage'] as Map<String, dynamic>? ?? {};
    final careJson = json['care_coverage'] as Map<String, dynamic>? ?? {};
    final copyParams = careJson['copy_params'] as Map<String, dynamic>?;

    return AwayPlanReadiness(
      carerCoverage: CarerCoverageFact(
        state: carerJson['state'] as String? ?? '',
        petsWithCarer: carerJson['pets_with_carer'] as int? ?? 0,
        petsTotal: carerJson['pets_total'] as int? ?? 0,
        copyKey: carerJson['copy_key'] as String? ?? '',
      ),
      careCoverage: CareCoverageFact(
        policyVersion: careJson['policy_version'] as String? ?? '1',
        coverageState: careJson['coverage_state'] as String? ?? '',
        reasonCodes:
            (careJson['reason_codes'] as List<dynamic>? ?? const [])
                .map((code) => code.toString())
                .toList(growable: false),
        reassuranceAvailable: careJson['reassurance_available'] == true,
        copyKey: careJson['copy_key'] as String? ?? '',
        copyCount: copyParams?['count'] as int?,
      ),
    );
  }
}
