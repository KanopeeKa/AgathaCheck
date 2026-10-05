import '../entities/pet_people.dart';
import '../enums/relationship_kind.dart';

/// Active primary-vet relationship for [people], if any.
PetRelationship? primaryVetRelationship(PetPeople? people) {
  if (people == null) return null;
  for (final r in people.relationships) {
    if (!r.active) continue;
    if (r.relationshipKind != RelationshipKind.primaryVet) continue;
    if (r.contactInactiveAt != null) continue;
    return r;
  }
  return null;
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
