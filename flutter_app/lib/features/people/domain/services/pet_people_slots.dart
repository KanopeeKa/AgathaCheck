import '../entities/pet_people.dart';
import '../enums/relationship_kind.dart';

bool petRelationshipIsVisible(PetRelationship r) {
  return r.active && r.contactInactiveAt == null;
}

/// Active primary-vet relationship for [people], if any.
PetRelationship? primaryVetRelationship(PetPeople? people) {
  if (people == null) return null;
  for (final r in people.relationships) {
    if (!petRelationshipIsVisible(r)) continue;
    if (r.relationshipKind != RelationshipKind.primaryVet) continue;
    return r;
  }
  return null;
}

/// Active out-of-hours vet for [people], if any.
PetRelationship? outOfHoursVetRelationship(PetPeople? people) {
  if (people == null) return null;
  for (final r in people.relationships) {
    if (!petRelationshipIsVisible(r)) continue;
    if (r.relationshipKind != RelationshipKind.outOfHoursVet) continue;
    return r;
  }
  return null;
}

/// Emergency contacts for [people] in server sort order.
List<PetRelationship> emergencyContactRelationships(PetPeople? people) {
  if (people == null) return const [];
  return people.relationships
      .where(
        (r) =>
            petRelationshipIsVisible(r) &&
            r.relationshipKind == RelationshipKind.emergencyContact,
      )
      .toList();
}

/// Relationships included on Away Planning handover exports.
List<PetRelationship> handoverPetRelationships(PetPeople people) {
  const kinds = {
    RelationshipKind.primaryVet,
    RelationshipKind.outOfHoursVet,
    RelationshipKind.emergencyContact,
  };
  final ordered = <PetRelationship>[];
  for (final kind in kinds) {
    for (final r in people.relationships) {
      if (!r.active) continue;
      if (r.relationshipKind != kind) continue;
      if (r.contactInactiveAt != null) continue;
      ordered.add(r);
    }
  }
  return ordered;
}
