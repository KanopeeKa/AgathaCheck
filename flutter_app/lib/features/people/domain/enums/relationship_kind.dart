enum RelationshipKind {
  primaryVet('primary_vet'),
  outOfHoursVet('out_of_hours_vet'),
  emergencyContact('emergency_contact'),
  careProvider('care_provider'),
  other('other');

  const RelationshipKind(this.wireValue);
  final String wireValue;

  static RelationshipKind fromWire(String? value) {
    for (final kind in RelationshipKind.values) {
      if (kind.wireValue == value) return kind;
    }
    return RelationshipKind.other;
  }
}
