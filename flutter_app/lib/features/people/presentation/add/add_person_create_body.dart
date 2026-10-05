import '../../domain/enums/contact_role.dart';
import '../edit/person_form_controller.dart';
import 'add_person_pet_selection.dart';

Map<String, dynamic> buildAddPersonCreateBody({
  required PersonFormController form,
  required List<AddPersonPetSelection> pets,
  String? householdId,
}) {
  final body = <String, dynamic>{
    'kind': form.kind.wireValue,
    'name': form.name.trim(),
    'roles': form.roles.map((r) => r.wireValue).toList(),
  };

  final phone = _trimOrNull(form.phone);
  if (phone != null) body['phone'] = phone;
  final email = _trimOrNull(form.email);
  if (email != null) body['email'] = email;
  final address = _trimOrNull(form.address);
  if (address != null) body['address'] = address;
  final website = _trimOrNull(form.website);
  if (website != null) body['website'] = website;
  final note = form.privateNote.trim();
  if (note.isNotEmpty) body['private_note'] = note;
  if (form.worksAtContactId != null) {
    body['works_at_contact_id'] = form.worksAtContactId;
  }
  if (householdId != null) {
    body['household_id'] = householdId;
  }

  final petLinks = pets
      .map((p) => p.toPetLinkJson())
      .whereType<Map<String, dynamic>>()
      .toList();
  if (petLinks.isNotEmpty) {
    body['pet_links'] = petLinks;
  }

  return body;
}

String? _trimOrNull(String value) {
  final t = value.trim();
  return t.isEmpty ? null : t;
}

bool rolesValidForAdd(Set<ContactRole> roles, {required bool requiresRoles}) {
  if (!requiresRoles) return true;
  return roles.isNotEmpty;
}
