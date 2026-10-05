import 'contact_summary.dart';
import 'household.dart';
import 'household_invite.dart';
import 'person.dart';

class Roster {
  const Roster({
    required this.households,
    required this.contacts,
    required this.pendingInvites,
  });

  final List<Household> households;
  final List<ContactSummary> contacts;
  final List<HouseholdInvite> pendingInvites;

  List<Person> get people {
    final out = <Person>[];
    for (final h in households) {
      for (final m in h.members) {
        out.add(HouseholdMemberPerson(household: h, member: m));
      }
    }
    for (final c in contacts) {
      out.add(ContactPerson(c));
    }
    for (final invite in pendingInvites) {
      out.add(PendingInvitePerson(invite));
    }
    return out;
  }

  ContactSummary? summaryById(String id) {
    for (final c in contacts) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    return other is Roster &&
        _listEq(other.households, households) &&
        _listEq(other.contacts, contacts) &&
        _listEq(other.pendingInvites, pendingInvites);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(households),
    Object.hashAll(contacts),
    Object.hashAll(pendingInvites),
  );
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
