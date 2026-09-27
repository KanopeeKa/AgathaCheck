import 'pet_access.dart';

/// Access granted via household membership (phase 3).
class HouseholdPetAccess {
  const HouseholdPetAccess({
    required this.userId,
    required this.accessTier,
    required this.isOrganiser,
    required this.householdId,
    required this.householdName,
    this.user,
    this.joinedAt,
  });

  final String userId;
  final String accessTier;
  final bool isOrganiser;
  final String householdId;
  final String householdName;
  final PetAccessUser? user;
  final DateTime? joinedAt;

  String get displayName {
    final u = user;
    if (u == null) return userId;
    final full = '${u.firstName} ${u.lastName}'.trim();
    return full.isEmpty ? userId : full;
  }

  String get tierLabel {
    if (isOrganiser) return 'Organiser · Full access';
    return accessTier == 'can_log_care' ? 'Can log care' : 'Full access';
  }
}

class PetAccessOverview {
  const PetAccessOverview({
    required this.directAccess,
    required this.householdAccess,
  });

  final List<PetAccess> directAccess;
  final List<HouseholdPetAccess> householdAccess;
}
