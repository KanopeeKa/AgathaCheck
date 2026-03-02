import '../../domain/entities/pet_access.dart';

class PetAccessUserModel extends PetAccessUser {
  const PetAccessUserModel({
    super.firstName,
    super.lastName,
    super.category,
    super.bio,
    super.photoUrl,
  });

  factory PetAccessUserModel.fromJson(Map<String, dynamic> json) {
    return PetAccessUserModel(
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'pet_guardian',
      bio: json['bio']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'category': category,
      'bio': bio,
      'photo_url': photoUrl,
    };
  }
}

class PetAccessModel extends PetAccess {
  const PetAccessModel({
    required super.id,
    required super.petId,
    required super.userId,
    required super.role,
    super.invitedBy,
    super.shareCode,
    required super.createdAt,
    super.user,
  });

  factory PetAccessModel.fromJson(Map<String, dynamic> json) {
    return PetAccessModel(
      id: json['id'] as int,
      petId: json['pet_id']?.toString() ?? '',
      userId: json['user_id'] as int,
      role: json['role'] == 'guardian'
          ? PetAccessRole.guardian
          : PetAccessRole.shared,
      invitedBy: json['invited_by'] as int?,
      shareCode: json['share_code']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      user: json['user'] != null
          ? PetAccessUserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'user_id': userId,
      'role': role == PetAccessRole.guardian ? 'guardian' : 'shared',
      'invited_by': invitedBy,
      'share_code': shareCode,
      'created_at': createdAt.toIso8601String(),
      if (user != null && user is PetAccessUserModel)
        'user': (user as PetAccessUserModel).toJson(),
    };
  }
}
