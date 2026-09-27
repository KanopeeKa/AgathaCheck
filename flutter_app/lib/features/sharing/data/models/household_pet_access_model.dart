import '../../domain/entities/household_pet_access.dart';
import '../../domain/entities/pet_access.dart';
import 'pet_access_model.dart';

class HouseholdPetAccessModel extends HouseholdPetAccess {
  const HouseholdPetAccessModel({
    required super.userId,
    required super.accessTier,
    required super.isOrganiser,
    required super.householdId,
    required super.householdName,
    super.user,
    super.joinedAt,
  });

  factory HouseholdPetAccessModel.fromJson(Map<String, dynamic> json) {
    return HouseholdPetAccessModel(
      userId: json['user_id']?.toString() ?? '',
      accessTier: json['access_tier']?.toString() ?? 'full_access',
      isOrganiser: json['is_organiser'] == true,
      householdId: json['household_id']?.toString() ?? '',
      householdName: json['household_name']?.toString() ?? '',
      joinedAt: DateTime.tryParse(json['joined_at']?.toString() ?? ''),
      user: json['user'] is Map<String, dynamic>
          ? PetAccessUserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PetAccessOverviewModel extends PetAccessOverview {
  const PetAccessOverviewModel({
    required super.directAccess,
    required super.householdAccess,
  });

  factory PetAccessOverviewModel.fromJson(Map<String, dynamic> json) {
    final direct = (json['access'] as List? ?? [])
        .map((e) => PetAccessModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final household = (json['household_access'] as List? ?? [])
        .map((e) => HouseholdPetAccessModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PetAccessOverviewModel(
      directAccess: direct,
      householdAccess: household,
    );
  }
}
