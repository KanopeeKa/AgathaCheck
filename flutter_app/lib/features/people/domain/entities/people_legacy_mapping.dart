import '../entities/contact_detail.dart';
import '../entities/contact_summary.dart';
import 'people_contact.dart';

PeopleContact peopleContactFromDetail(ContactDetail detail) {
  return PeopleContact(
    id: detail.id,
    kind: detail.kind.wireValue,
    name: detail.name,
    roles: detail.roles.map((r) => r.wireValue).toList(),
    phone: detail.phone,
    email: detail.email,
    address: detail.address,
    website: detail.website,
    privateNote: detail.privateNote,
    inactiveAt: detail.inactiveAt,
    legacyVetId: detail.legacyVetId,
    worksAtContactId: detail.worksAtContactId,
  );
}

PeopleContact peopleContactFromSummary(ContactSummary summary) {
  return PeopleContact(
    id: summary.id,
    kind: summary.kind.wireValue,
    name: summary.name,
    roles: summary.roles.map((r) => r.wireValue).toList(),
    inactiveAt: summary.inactiveAt,
    legacyVetId: summary.legacyVetId,
  );
}
