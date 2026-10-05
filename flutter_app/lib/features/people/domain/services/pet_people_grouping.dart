import '../entities/pet_people.dart';
import '../enums/relationship_kind.dart';
import 'pet_people_slots.dart';

bool petPeopleRelationshipIsProfessional(PetRelationship relationship) {
  if (relationship.relationshipKind == RelationshipKind.primaryVet ||
      relationship.relationshipKind == RelationshipKind.outOfHoursVet) {
    return true;
  }
  if (relationship.contactKind == 'organisation') return true;
  return false;
}

bool petPeopleRelationshipIsCarer(PetRelationship relationship) {
  if (petPeopleRelationshipIsProfessional(relationship)) return false;
  switch (relationship.relationshipKind) {
    case RelationshipKind.emergencyContact:
    case RelationshipKind.careProvider:
    case RelationshipKind.other:
      return true;
    case RelationshipKind.primaryVet:
    case RelationshipKind.outOfHoursVet:
      return false;
  }
}

List<PetRelationship> trustedCarerRelationships(PetPeople people) {
  final seen = <String>{};
  final rows = <PetRelationship>[];
  for (final relationship in people.relationships) {
    if (!petRelationshipIsVisible(relationship)) continue;
    if (!petPeopleRelationshipIsCarer(relationship)) continue;
    if (!seen.add(relationship.contactId)) continue;
    rows.add(relationship);
  }
  return rows;
}

List<PetRelationship> professionalRelationships(PetPeople people) {
  final seen = <String>{};
  final rows = <PetRelationship>[];
  for (final relationship in people.relationships) {
    if (!petRelationshipIsVisible(relationship)) continue;
    if (!petPeopleRelationshipIsProfessional(relationship)) continue;
    if (!seen.add(relationship.contactId)) continue;
    rows.add(relationship);
  }
  return rows;
}
