import '../../domain/entities/away_plan_readiness.dart';
class AwayPlanReadinessModel {
  static AwayPlanReadiness fromJson(Map<String, dynamic> json) {
    final t = json['tile_copy'] as Map<String, dynamic>? ?? {};
    final raw = t['copy_params'] as Map<String, dynamic>?;
    Map<String, int>? params;
    if (raw != null) params = raw.map((k,v)=>MapEntry(k,(v as num).toInt()));
    return AwayPlanReadiness(tileCopy: AwayPlanTileCopy(
      source: t['source'] as String? ?? '', copyKey: t['copy_key'] as String? ?? '', copyParams: params));
  }
}
