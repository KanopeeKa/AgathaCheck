import '../entities/org_person.dart';
import 'admin_contacts.dart';

/// Viewer is the signed-in person row.
bool viewerIsSelfPerson(OrgPersonSummary person, String? viewerUserId) {
  return viewerUserId != null && person.userId == viewerUserId;
}

/// Client-side name filter for the people directory.
List<OrgPersonSummary> filterOrgPeopleByName(
  List<OrgPersonSummary> people,
  String query,
) {
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) return people;
  return people
      .where((person) => person.displayName.toLowerCase().contains(trimmed))
      .toList();
}

/// Optional route filter (e.g. `filter=admins`).
List<OrgPersonSummary> filterOrgPeopleByRoute(
  List<OrgPersonSummary> people, {
  String? filter,
}) {
  if (filter == 'admins') {
    return people.where(isAdminDirectoryContact).toList();
  }
  return people;
}

/// All people: self pinned first, then alphabetical by last name.
List<OrgPersonSummary> sortOrgPeople({
  required List<OrgPersonSummary> people,
  required String? viewerUserId,
}) {
  OrgPersonSummary? self;
  final others = <OrgPersonSummary>[];

  for (final person in people) {
    if (viewerIsSelfPerson(person, viewerUserId)) {
      self = person;
    } else {
      others.add(person);
    }
  }

  others.sort((a, b) {
    final last = adminContactSortKey(a).compareTo(adminContactSortKey(b));
    if (last != 0) return last;
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });

  if (self == null) return others;
  return [self, ...others];
}
