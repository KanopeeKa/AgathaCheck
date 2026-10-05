import '../enums/relationship_kind.dart';

class RelatedCarePet {
  const RelatedCarePet({
    required this.petId,
    required this.petName,
    required this.relationshipKind,
  });

  final String petId;
  final String petName;
  final RelationshipKind relationshipKind;

  @override
  bool operator ==(Object other) {
    return other is RelatedCarePet &&
        other.petId == petId &&
        other.petName == petName &&
        other.relationshipKind == relationshipKind;
  }

  @override
  int get hashCode => Object.hash(petId, petName, relationshipKind);
}

class RelatedCareItem {
  const RelatedCareItem({
    required this.id,
    required this.name,
    required this.petId,
  });

  final String id;
  final String name;
  final String petId;

  @override
  bool operator ==(Object other) {
    return other is RelatedCareItem &&
        other.id == id &&
        other.name == name &&
        other.petId == petId;
  }

  @override
  int get hashCode => Object.hash(id, name, petId);
}

class RelatedCareAbsence {
  const RelatedCareAbsence({
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
    return other is RelatedCareAbsence &&
        other.absenceId == absenceId &&
        other.startsOn == startsOn &&
        other.endsOn == endsOn &&
        _listEq(other.petIds, petIds);
  }

  @override
  int get hashCode =>
      Object.hash(absenceId, startsOn, endsOn, Object.hashAll(petIds));
}

class RelatedCare {
  const RelatedCare({
    required this.pets,
    required this.careItems,
    required this.absences,
    required this.historyCount,
  });

  final List<RelatedCarePet> pets;
  final List<RelatedCareItem> careItems;
  final List<RelatedCareAbsence> absences;
  final int historyCount;

  @override
  bool operator ==(Object other) {
    return other is RelatedCare &&
        _listEq(other.pets, pets) &&
        _listEq(other.careItems, careItems) &&
        _listEq(other.absences, absences) &&
        other.historyCount == historyCount;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(pets),
    Object.hashAll(careItems),
    Object.hashAll(absences),
    historyCount,
  );
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
