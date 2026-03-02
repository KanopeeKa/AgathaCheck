enum PetAccessRole { guardian, shared }

class PetAccessUser {
  final String firstName;
  final String lastName;
  final String category;
  final String bio;
  final String photoUrl;

  const PetAccessUser({
    this.firstName = '',
    this.lastName = '',
    this.category = 'pet_guardian',
    this.bio = '',
    this.photoUrl = '',
  });

  String get displayName {
    final full = '$firstName $lastName'.trim();
    if (full.isNotEmpty) return full;
    return 'Unknown User';
  }

  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }
    final dn = displayName;
    if (dn.length >= 2) return dn.substring(0, 2).toUpperCase();
    if (dn.isNotEmpty) return dn[0].toUpperCase();
    return '?';
  }
}

class PetAccess {
  final int id;
  final String petId;
  final int userId;
  final PetAccessRole role;
  final int? invitedBy;
  final String? shareCode;
  final DateTime createdAt;
  final PetAccessUser? user;

  const PetAccess({
    required this.id,
    required this.petId,
    required this.userId,
    required this.role,
    this.invitedBy,
    this.shareCode,
    required this.createdAt,
    this.user,
  });
}
