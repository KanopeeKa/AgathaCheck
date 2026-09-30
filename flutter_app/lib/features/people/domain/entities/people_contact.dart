class PeopleContact {
  const PeopleContact({
    required this.id,
    required this.kind,
    required this.name,
    required this.roles,
    this.phone,
    this.email,
    this.address,
    this.website,
    this.privateNote = '',
    this.inactiveAt,
    this.legacyVetId,
    this.worksAtContactId,
  });

  final String id;
  final String kind;
  final String name;
  final List<String> roles;
  final String? phone;
  final String? email;
  final String? address;
  final String? website;
  final String privateNote;
  final DateTime? inactiveAt;
  final String? legacyVetId;
  final String? worksAtContactId;

  static const professionalRoles = {
    'vet',
    'vet_nurse',
    'groomer',
    'trainer',
    'behaviourist',
    'boarding',
  };

  bool get isProfessional =>
      roles.any((r) => professionalRoles.contains(r)) ||
      (roles.isEmpty && kind == 'organisation');

  bool get isCarer =>
      roles.any((r) => !professionalRoles.contains(r) && r != 'other') ||
      roles.contains('sitter') ||
      roles.contains('walker') ||
      roles.contains('emergency_contact');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PeopleContact &&
        other.id == id &&
        other.kind == kind &&
        other.name == name &&
        _listEq(other.roles, roles) &&
        other.phone == phone &&
        other.email == email &&
        other.address == address &&
        other.website == website &&
        other.privateNote == privateNote &&
        other.inactiveAt == inactiveAt &&
        other.legacyVetId == legacyVetId &&
        other.worksAtContactId == worksAtContactId;
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    name,
    Object.hashAll(roles),
    phone,
    email,
    address,
    website,
    privateNote,
    inactiveAt,
    legacyVetId,
    worksAtContactId,
  );

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
