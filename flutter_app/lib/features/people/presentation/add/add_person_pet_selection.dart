import '../../domain/enums/relationship_kind.dart';

class AddPersonPetSelection {
  AddPersonPetSelection({
    required this.petId,
    required this.petName,
    this.selected = false,
    this.relationshipKind = RelationshipKind.careProvider,
    this.emergencyContact = false,
  });

  final String petId;
  final String petName;
  bool selected;
  RelationshipKind relationshipKind;
  bool emergencyContact;

  Map<String, dynamic>? toPetLinkJson() {
    if (!selected) return null;
    final kind = emergencyContact
        ? RelationshipKind.emergencyContact
        : relationshipKind;
    return {'pet_id': petId, 'relationship_kind': kind.wireValue};
  }
}
