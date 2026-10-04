class HouseholdInvite {
  const HouseholdInvite({
    required this.id,
    required this.source,
    required this.email,
    this.contactId,
    this.householdId,
    required this.petIds,
    this.createdAt,
  });

  final String id;
  final String source;
  final String email;
  final String? contactId;
  final String? householdId;
  final List<String> petIds;
  final String? createdAt;

  @override
  bool operator ==(Object other) {
    return other is HouseholdInvite &&
        other.id == id &&
        other.source == source &&
        other.email == email &&
        other.contactId == contactId &&
        other.householdId == householdId &&
        _listEq(other.petIds, petIds) &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    source,
    email,
    contactId,
    householdId,
    Object.hashAll(petIds),
    createdAt,
  );
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
