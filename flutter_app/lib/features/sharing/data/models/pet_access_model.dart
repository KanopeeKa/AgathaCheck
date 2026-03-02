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
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      petId: json['pet_id']?.toString() ?? '',
      userId: json['user_id'] is int ? json['user_id'] as int : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      role: json['role'] == 'guardian'
          ? PetAccessRole.guardian
          : PetAccessRole.shared,
      invitedBy: json['invited_by'] != null
          ? (json['invited_by'] is int ? json['invited_by'] as int : int.tryParse(json['invited_by'].toString()))
          : null,
      shareCode: json['share_code']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      user: json['user'] != null && json['user'] is Map<String, dynamic>
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
