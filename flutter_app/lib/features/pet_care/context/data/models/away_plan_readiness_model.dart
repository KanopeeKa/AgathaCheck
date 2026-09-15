import '../../domain/entities/away_plan_readiness.dart';

class AwayPlanReadinessModel {
  static AwayPlanReadiness fromJson(Map<String, dynamic> json) {
    final tileJson = json['tile_copy'] as Map<String, dynamic>? ?? {};
    final copyParams = tileJson['copy_params'] as Map<String, dynamic>?;

    return AwayPlanReadiness(
      tileCopy: AwayPlanTileCopy(
        source: tileJson['source'] as String? ?? '',
        copyKey: tileJson['copy_key'] as String? ?? '',
        copyParams: copyParams == null
            ? null
            : Map<String, dynamic>.from(copyParams),
      ),
    );
  }
}
