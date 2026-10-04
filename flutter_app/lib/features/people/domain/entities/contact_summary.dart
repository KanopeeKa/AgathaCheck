import '../enums/contact_group.dart';
import '../enums/contact_kind.dart';
import '../enums/contact_role.dart';
import '../enums/contact_status.dart';
import '../enums/relationship_kind.dart';

class ContactDirectoryRef {
  const ContactDirectoryRef({required this.type, this.householdId});

  final String type;
  final String? householdId;

  bool get isHousehold => type == 'household';

  @override
  bool operator ==(Object other) {
    return other is ContactDirectoryRef &&
        other.type == type &&
        other.householdId == householdId;
  }

  @override
  int get hashCode => Object.hash(type, householdId);
}

class ContactPetLink {
  const ContactPetLink({
    required this.petId,
    required this.petName,
    required this.relationshipKind,
    this.isPrimary = false,
  });

  final String petId;
  final String petName;
  final RelationshipKind relationshipKind;
  final bool isPrimary;

  @override
  bool operator ==(Object other) {
    return other is ContactPetLink &&
        other.petId == petId &&
        other.petName == petName &&
        other.relationshipKind == relationshipKind &&
        other.isPrimary == isPrimary;
  }

  @override
  int get hashCode => Object.hash(petId, petName, relationshipKind, isPrimary);
}

class ContactWorksAt {
  const ContactWorksAt({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) {
    return other is ContactWorksAt && other.id == id && other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);
}

class ContactNextAbsence {
  const ContactNextAbsence({
    required this.absenceId,
    required this.startsOn,
    required this.endsOn,
    required this.petIds,
  });

  final String absenceId;
  final String startsOn;
  final String endsOn;
  final List<String> petIds;

  @override
  bool operator ==(Object other) {
    return other is ContactNextAbsence &&
        other.absenceId == absenceId &&
        other.startsOn == startsOn &&
        other.endsOn == endsOn &&
        _listEq(other.petIds, petIds);
  }

  @override
  int get hashCode =>
      Object.hash(absenceId, startsOn, endsOn, Object.hashAll(petIds));
}

class ContactAccessLine {
  const ContactAccessLine({required this.role, this.petId, this.expiresAt});

  final String role;
  final String? petId;
  final DateTime? expiresAt;

  @override
  bool operator ==(Object other) {
    return other is ContactAccessLine &&
        other.role == role &&
        other.petId == petId &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode => Object.hash(role, petId, expiresAt);
}

class ContactSummary {
  const ContactSummary({
    required this.id,
    required this.directory,
    required this.kind,
    required this.name,
    required this.roles,
    required this.group,
    required this.status,
    this.linkedUserId,
    this.pets = const [],
    this.worksAt,
    this.nextAbsence,
    this.access,
    this.legacyVetId,
    this.inactiveAt,
  });

  final String id;
  final ContactDirectoryRef directory;
  final ContactKind kind;
  final String name;
  final List<ContactRole> roles;
  final ContactGroup group;
  final ContactStatus status;
  final String? linkedUserId;
  final List<ContactPetLink> pets;
  final ContactWorksAt? worksAt;
  final ContactNextAbsence? nextAbsence;
  final ContactAccessLine? access;
  final String? legacyVetId;
  final DateTime? inactiveAt;

  bool get isInactive => status == ContactStatus.inactive;

  @override
  bool operator ==(Object other) {
    return other is ContactSummary &&
        other.id == id &&
        other.directory == directory &&
        other.kind == kind &&
        other.name == name &&
        _listEq(other.roles, roles) &&
        other.group == group &&
        other.status == status &&
        other.linkedUserId == linkedUserId &&
        _listEq(other.pets, pets) &&
        other.worksAt == worksAt &&
        other.nextAbsence == nextAbsence &&
        other.access == access &&
        other.legacyVetId == legacyVetId &&
        other.inactiveAt == inactiveAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    directory,
    kind,
    name,
    Object.hashAll(roles),
    group,
    status,
    linkedUserId,
    Object.hashAll(pets),
    worksAt,
    nextAbsence,
    access,
    legacyVetId,
    inactiveAt,
  );
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
