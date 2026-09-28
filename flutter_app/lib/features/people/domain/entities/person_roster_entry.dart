import 'people_contact.dart';

/// UI aggregate for one row on the People hub or desk (backend may stay multi-table).
enum PersonRosterSource { contact, householdMember, pendingInvite }

class PersonRosterEntry {
  const PersonRosterEntry({
    required this.id,
    required this.displayName,
    required this.source,
    this.contact,
    this.subtitle,
    this.linkedPetCount,
    this.statusLabel,
  });

  final String id;
  final String displayName;
  final PersonRosterSource source;
  final PeopleContact? contact;
  final String? subtitle;
  final int? linkedPetCount;
  final String? statusLabel;

  factory PersonRosterEntry.fromContact(
    PeopleContact contact, {
    String? subtitle,
    int? linkedPetCount,
    String? statusLabel,
  }) {
    return PersonRosterEntry(
      id: contact.id,
      displayName: contact.name,
      source: PersonRosterSource.contact,
      contact: contact,
      subtitle: subtitle,
      linkedPetCount: linkedPetCount,
      statusLabel: statusLabel,
    );
  }

  String get roleLine {
    if (subtitle != null && subtitle!.isNotEmpty) return subtitle!;
    final c = contact;
    if (c == null) return '';
    if (c.roles.isEmpty) return c.kind;
    return c.roles.join(' · ');
  }
}
