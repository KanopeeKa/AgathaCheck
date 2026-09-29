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
      worksAtContactId: json['works_at_contact_id'] as String?,
    );
  }

  /// Builds a PATCH body with only changed fields. Pass explicit empty strings to clear.
  Map<String, dynamic> buildPatchComparedTo(PeopleContactModel original) {
    final patch = <String, dynamic>{};
    if (name != original.name) patch['name'] = name;
    if (kind != original.kind) patch['kind'] = kind;
    if (!_nullableEq(phone, original.phone)) patch['phone'] = phone ?? '';
    if (!_nullableEq(email, original.email)) patch['email'] = email ?? '';
    if (!_nullableEq(address, original.address)) patch['address'] = address ?? '';
    if (!_nullableEq(website, original.website)) patch['website'] = website ?? '';
    if (privateNote != original.privateNote) {
      patch['private_note'] = privateNote;
    }
    if (!_roleListsEqual(roles, original.roles)) {
      patch['roles'] = roles;
    }
    if (worksAtContactId != original.worksAtContactId) {
      patch['works_at_contact_id'] = worksAtContactId ?? '';
    }
    return patch;
  }

  static bool _nullableEq(String? a, String? b) =>
      (a ?? '').trim() == (b ?? '').trim();

  static bool _roleListsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sa = a.toSet();
    final sb = b.toSet();
    return sa.length == sb.length && sa.containsAll(sb);
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
      worksAtContactId: worksAtContactId,
    );
  }

  Map<String, dynamic> toCreateJson() => {
    'kind': kind,
    'name': name,
    if (roles.isNotEmpty) 'roles': roles,
    if (phone != null && phone!.isNotEmpty) 'phone': phone,
    if (email != null && email!.isNotEmpty) 'email': email,
    if (address != null && address!.isNotEmpty) 'address': address,
    if (website != null && website!.isNotEmpty) 'website': website,
    if (worksAtContactId != null && worksAtContactId!.isNotEmpty)
      'works_at_contact_id': worksAtContactId,
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
    worksAtContactId: worksAtContactId,
  );
}
