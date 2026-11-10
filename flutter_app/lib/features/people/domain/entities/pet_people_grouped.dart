import '../enums/relationship_kind.dart';

/// Ordered groups for the pet profile "People around {pet}" section (D-040).
class PetPeopleGroupedSection {
  const PetPeopleGroupedSection({
    required this.vets,
    this.emergencyContacts,
    required this.atHome,
    this.trustedCarers,
    this.otherProfessionals,
  });

  final PetPeopleVetsGroup vets;
  final List<PetPeopleGroupedContactRow>? emergencyContacts;
  final PetPeopleAtHomeGroup atHome;
  final List<PetPeopleGroupedContactRow>? trustedCarers;
  final List<PetPeopleGroupedContactRow>? otherProfessionals;
}

class PetPeopleVetsGroup {
  const PetPeopleVetsGroup({required this.hasPrimaryVet, required this.rows});

  final bool hasPrimaryVet;
  final List<PetPeopleGroupedContactRow> rows;
}

class PetPeopleAtHomeGroup {
  const PetPeopleAtHomeGroup({required this.rows});

  final List<PetPeopleGroupedMemberRow> rows;
}

class PetPeopleGroupedContactRow {
  const PetPeopleGroupedContactRow({
    required this.contactId,
    required this.name,
    required this.contactKind,
    required this.contactRoles,
    required this.slotKinds,
    this.phone,
    this.emergencySortOrder = 0,
  });

  final String contactId;
  final String name;
  final String contactKind;
  final List<String> contactRoles;
  final List<RelationshipKind> slotKinds;
  final String? phone;
  final int emergencySortOrder;
}

class PetPeopleGroupedMemberRow {
  const PetPeopleGroupedMemberRow({
    required this.userId,
    required this.displayName,
    required this.isOwner,
    required this.tier,
    required this.isOrganiser,
    this.photoUrl,
  });

  final String userId;
  final String displayName;
  final bool isOwner;
  final String tier;
  final bool isOrganiser;
  final String? photoUrl;
}
