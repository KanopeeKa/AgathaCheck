class Household {
  const Household({
    required this.id,
    required this.name,
    required this.myTier,
    required this.myIsOrganiser,
    required this.members,
  });

  final String id;
  final String name;
  final String myTier;
  final bool myIsOrganiser;
  final List<HouseholdMember> members;

  @override
  bool operator ==(Object other) {
    return other is Household &&
        other.id == id &&
        other.name == name &&
        other.myTier == myTier &&
        other.myIsOrganiser == myIsOrganiser &&
        _listEq(other.members, members);
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    myTier,
    myIsOrganiser,
    Object.hashAll(members),
  );
}

class HouseholdMember {
  const HouseholdMember({
    required this.userId,
    required this.displayName,
    required this.firstName,
    required this.tier,
    required this.isOrganiser,
    required this.isYou,
    required this.ownsPetIds,
    required this.sharesPetIds,
  });

  final String userId;
  final String displayName;
  final String firstName;
  final String tier;
  final bool isOrganiser;
  final bool isYou;
  final List<String> ownsPetIds;
  final List<String> sharesPetIds;

  @override
  bool operator ==(Object other) {
    return other is HouseholdMember &&
        other.userId == userId &&
        other.displayName == displayName &&
        other.firstName == firstName &&
        other.tier == tier &&
        other.isOrganiser == isOrganiser &&
        other.isYou == isYou &&
        _listEq(other.ownsPetIds, ownsPetIds) &&
        _listEq(other.sharesPetIds, sharesPetIds);
  }

  @override
  int get hashCode => Object.hash(
    userId,
    displayName,
    firstName,
    tier,
    isOrganiser,
    isYou,
    Object.hashAll(ownsPetIds),
    Object.hashAll(sharesPetIds),
  );
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
