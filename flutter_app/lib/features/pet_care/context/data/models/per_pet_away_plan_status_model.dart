import '../../domain/entities/per_pet_away_plan_status.dart';

class PerPetAwayPlanStatusModel {
  static PerPetAwayPlanStatus fromStatusJson(Map<String, dynamic> json) {
    final copyParamsRaw = json['copy_params'];
    final copyParams = copyParamsRaw is Map<String, dynamic>
        ? Map<String, Object?>.from(copyParamsRaw)
        : const <String, Object?>{};
    return PerPetAwayPlanStatus(
      priority: json['priority'] as String? ?? 'none',
      carerState: json['carer_state'] as String? ?? 'unset',
      reviewCareItemCount:
          (json['review_care_item_count'] as num?)?.toInt() ?? 0,
      copyKey: json['copy_key'] as String?,
      copyParams: copyParams,
    );
  }
}
