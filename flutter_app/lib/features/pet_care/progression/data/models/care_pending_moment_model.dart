import '../../domain/entities/care_pending_moment.dart';

class CarePendingMomentModel {
  const CarePendingMomentModel({
    required this.petId,
    required this.bundleId,
    required this.primaryMilestoneType,
    required this.includesFirstCare,
    required this.achievedAt,
    required this.milestones,
  });

  final String petId;
  final String bundleId;
  final String primaryMilestoneType;
  final bool includesFirstCare;
  final DateTime achievedAt;
  final List<CareMilestoneSummaryModel> milestones;

  factory CarePendingMomentModel.fromJson(
    String petId,
    Map<String, dynamic> json,
  ) {
    final achievedRaw = json['achieved_at'] as String?;
    final achievedAt = achievedRaw != null
        ? DateTime.tryParse(achievedRaw)
        : null;
    if (achievedAt == null) {
      throw FormatException('Missing achieved_at for pending moment');
    }
    final milestoneList = json['milestones'] as List<dynamic>? ?? [];
    return CarePendingMomentModel(
      petId: petId,
      bundleId: json['bundle_id'] as String,
      primaryMilestoneType: json['primary_milestone_type'] as String,
      includesFirstCare: json['includes_first_care'] as bool? ?? false,
      achievedAt: achievedAt,
      milestones: milestoneList
          .map(
            (item) => CareMilestoneSummaryModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  CarePendingMoment toEntity() => CarePendingMoment(
    petId: petId,
    bundleId: bundleId,
    primaryMilestoneType: primaryMilestoneType,
    includesFirstCare: includesFirstCare,
    achievedAt: achievedAt,
    milestones: milestones.map((m) => m.toEntity()).toList(),
  );
}

class CareMilestoneSummaryModel {
  const CareMilestoneSummaryModel({
    required this.id,
    required this.milestoneType,
    required this.careFamily,
    required this.achievedAt,
    required this.policyVersion,
    required this.bundleId,
  });

  final String id;
  final String milestoneType;
  final String? careFamily;
  final DateTime achievedAt;
  final String policyVersion;
  final String? bundleId;

  factory CareMilestoneSummaryModel.fromJson(Map<String, dynamic> json) {
    final achievedRaw = json['achieved_at'] as String?;
    final achievedAt = achievedRaw != null
        ? DateTime.tryParse(achievedRaw)
        : null;
    if (achievedAt == null) {
      throw FormatException('Missing achieved_at for milestone summary');
    }
    return CareMilestoneSummaryModel(
      id: json['id'] as String,
      milestoneType: json['milestone_type'] as String,
      careFamily: json['care_family'] as String?,
      achievedAt: achievedAt,
      policyVersion: json['policy_version'] as String,
      bundleId: json['bundle_id'] as String?,
    );
  }

  CareMilestoneSummary toEntity() => CareMilestoneSummary(
    id: id,
    milestoneType: milestoneType,
    careFamily: careFamily,
    achievedAt: achievedAt,
    policyVersion: policyVersion,
    bundleId: bundleId,
  );
}

class CarePendingMomentsResponseModel {
  const CarePendingMomentsResponseModel({
    required this.moments,
    required this.throttled,
  });

  final List<CarePendingMomentModel> moments;
  final bool throttled;

  factory CarePendingMomentsResponseModel.fromJson(
    String petId,
    Map<String, dynamic> json,
  ) {
    final list = json['moments'] as List<dynamic>? ?? [];
    return CarePendingMomentsResponseModel(
      moments: list
          .map(
            (item) => CarePendingMomentModel.fromJson(
              petId,
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      throttled: json['throttled'] as bool? ?? false,
    );
  }

  CarePendingMomentsResponse toEntity() => CarePendingMomentsResponse(
    moments: moments.map((m) => m.toEntity()).toList(),
    throttled: throttled,
  );
}
