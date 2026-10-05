import 'contact_group.dart';

enum ContactRole {
  sitter('sitter', ContactGroup.carer),
  walker('walker', ContactGroup.carer),
  emergencyContact('emergency_contact', ContactGroup.carer),
  other('other', ContactGroup.carer),
  vet('vet', ContactGroup.professional),
  vetNurse('vet_nurse', ContactGroup.professional),
  groomer('groomer', ContactGroup.professional),
  trainer('trainer', ContactGroup.professional),
  behaviourist('behaviourist', ContactGroup.professional),
  boarding('boarding', ContactGroup.professional);

  const ContactRole(this.wireValue, this.group);
  final String wireValue;
  final ContactGroup group;

  static ContactRole fromWire(String value) {
    for (final role in ContactRole.values) {
      if (role.wireValue == value) return role;
    }
    return ContactRole.other;
  }

  static List<ContactRole> fromWireList(List<dynamic>? raw) {
    if (raw == null || raw.isEmpty) return const [];
    return raw.map((e) => fromWire(e.toString())).toList();
  }
}
