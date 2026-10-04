import '../entities/contact_summary.dart';

/// Normalizes a query for matching lowercase text.
String normalizePeopleQuery(String raw) => raw.trim().toLowerCase();

bool contactMatchesQuery(ContactSummary contact, String query) {
  if (query.isEmpty) return true;
  final q = normalizePeopleQuery(query);

  if (contact.name.toLowerCase().contains(q)) return true;

  for (final role in contact.roles) {
    if (role.wireValue.contains(q)) return true;
  }

  if (contact.worksAt != null &&
      contact.worksAt!.name.toLowerCase().contains(q)) {
    return true;
  }

  for (final pet in contact.pets) {
    if (pet.petName.toLowerCase().contains(q)) return true;
  }

  return false;
}

List<ContactSummary> filterContactsByQuery(
  List<ContactSummary> contacts,
  String query,
) {
  if (query.trim().isEmpty) return contacts;
  return contacts.where((c) => contactMatchesQuery(c, query)).toList();
}

int contactSearchScore(ContactSummary contact, String query) {
  if (query.isEmpty) return 0;
  final q = normalizePeopleQuery(query);
  final name = contact.name.toLowerCase();
  if (name == q) return 100;
  if (name.startsWith(q)) return 80;
  if (name.contains(q)) return 60;
  for (final role in contact.roles) {
    if (role.wireValue.contains(q)) return 40;
  }
  for (final pet in contact.pets) {
    if (pet.petName.toLowerCase().contains(q)) return 30;
  }
  return 0;
}

List<ContactSummary> searchContacts(
  List<ContactSummary> contacts,
  String query,
) {
  final filtered = filterContactsByQuery(contacts, query);
  filtered.sort((a, b) {
    final scoreDiff =
        contactSearchScore(b, query).compareTo(contactSearchScore(a, query));
    if (scoreDiff != 0) return scoreDiff;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return filtered;
}
