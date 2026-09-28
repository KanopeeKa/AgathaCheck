import '../../domain/entities/people_contact.dart';

class PeopleContactModel {
  PeopleContactModel({
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

  factory PeopleContactModel.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    return PeopleContactModel(
      id: json['id'] as String,
      kind: json['kind'] as String,
      name: json['name'] as String,
      roles: rolesRaw is List
          ? rolesRaw.map((e) => e.toString()).toList()
          : const [],
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      website: json['website'] as String?,
      privateNote: json['private_note'] as String? ?? '',
      inactiveAt: json['inactive_at'] != null
          ? DateTime.tryParse(json['inactive_at'] as String)
          : null,
      legacyVetId: json['legacy_vet_id'] as String?,
    );
  }

  Map<String, dynamic> toPatchJson({String? privateNote}) => {
    if (privateNote != null) 'private_note': privateNote,
  };

  PeopleContactModel copyWith({String? privateNote}) {
    return PeopleContactModel(
      id: id,
      kind: kind,
      name: name,
      roles: roles,
      phone: phone,
      email: email,
      address: address,
      website: website,
      privateNote: privateNote ?? this.privateNote,
      inactiveAt: inactiveAt,
      legacyVetId: legacyVetId,
    );
  }

  Map<String, dynamic> toCreateJson() => {
    'kind': kind,
    'name': name,
    if (roles.isNotEmpty) 'roles': roles,
    if (phone != null && phone!.isNotEmpty) 'phone': phone,
    if (email != null && email!.isNotEmpty) 'email': email,
    if (privateNote.isNotEmpty) 'private_note': privateNote,
  };

  PeopleContact toEntity() => PeopleContact(
    id: id,
    kind: kind,
    name: name,
    roles: roles,
    phone: phone,
    email: email,
    address: address,
    website: website,
    privateNote: privateNote,
    inactiveAt: inactiveAt,
    legacyVetId: legacyVetId,
  );
}
