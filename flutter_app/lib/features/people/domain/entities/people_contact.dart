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
}
