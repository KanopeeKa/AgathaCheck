import '../enums/relationship_kind.dart';

class PetRelationship {
  const PetRelationship({
    required this.id,
    required this.petId,
    required this.contactId,
    required this.relationshipKind,
    required this.isPrimary,
    required this.active,
    required this.contactKind,
    required this.contactName,
    this.contactPhone,
    this.contactInactiveAt,
  });

  final String id;
  final String petId;
  final String contactId;
  final RelationshipKind relationshipKind;
  final bool isPrimary;
  final bool active;
  final String contactKind;
  final String contactName;
  final String? contactPhone;
  final DateTime? contactInactiveAt;

  @override
  bool operator ==(Object other) {
    return other is PetRelationship &&
        other.id == id &&
        other.petId == petId &&
        other.contactId == contactId &&
        other.relationshipKind == relationshipKind &&
        other.isPrimary == isPrimary &&
        other.active == active &&
        other.contactKind == contactKind &&
        other.contactName == contactName &&
        other.contactPhone == contactPhone &&
        other.contactInactiveAt == contactInactiveAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    petId,
    contactId,
    relationshipKind,
    isPrimary,
    active,
    contactKind,
    contactName,
    contactPhone,
    contactInactiveAt,
  );
}

class PetPeopleOwner {
  const PetPeopleOwner({required this.userId, required this.displayName});

  final String userId;
  final String displayName;

  @override
  bool operator ==(Object other) {
    return other is PetPeopleOwner &&
        other.userId == userId &&
        other.displayName == displayName;
  }

  @override
  int get hashCode => Object.hash(userId, displayName);
}

class PetPeople {
  const PetPeople({
    required this.petId,
    required this.petName,
    required this.scope,
    required this.owner,
    required this.householdMembers,
    required this.relationships,
  });

  final String petId;
  final String petName;
  final String scope;
  final PetPeopleOwner owner;
  final List<HouseholdMemberSnapshot> householdMembers;
  final List<PetRelationship> relationships;

  @override
  bool operator ==(Object other) {
    return other is PetPeople &&
        other.petId == petId &&
        other.petName == petName &&
        other.scope == scope &&
        other.owner == owner &&
        _listEq(other.householdMembers, householdMembers) &&
        _listEq(other.relationships, relationships);
  }

  @override
  int get hashCode => Object.hash(
    petId,
    petName,
    scope,
    owner,
    Object.hashAll(householdMembers),
    Object.hashAll(relationships),
  );
}

class HouseholdMemberSnapshot {
  const HouseholdMemberSnapshot({
    required this.userId,
    required this.displayName,
    required this.firstName,
    required this.tier,
    required this.isOrganiser,
  });

  final String userId;
  final String displayName;
  final String firstName;
  final String tier;
  final bool isOrganiser;

  @override
  bool operator ==(Object other) {
    return other is HouseholdMemberSnapshot &&
        other.userId == userId &&
        other.displayName == displayName &&
        other.firstName == firstName &&
        other.tier == tier &&
        other.isOrganiser == isOrganiser;
  }

  @override
  int get hashCode =>
      Object.hash(userId, displayName, firstName, tier, isOrganiser);
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
