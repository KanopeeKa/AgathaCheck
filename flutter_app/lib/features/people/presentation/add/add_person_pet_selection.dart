import '../../domain/enums/relationship_kind.dart';

class AddPersonPetSelection {
  AddPersonPetSelection({
    required this.petId,
    required this.petName,
    this.selected = false,
    this.relationshipKind,
    this.emergencyContact = false,
  });

  final String petId;
  final String petName;
  bool selected;
  RelationshipKind? relationshipKind;
  bool emergencyContact;

  bool get linkKindChosen =>
      emergencyContact || relationshipKind != null;

  Map<String, dynamic>? toPetLinkJson() {
    if (!selected || !linkKindChosen) return null;
    final kind = emergencyContact
        ? RelationshipKind.emergencyContact
        : relationshipKind!;
    return {'pet_id': petId, 'relationship_kind': kind.wireValue};
  }
}
