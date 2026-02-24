import '../../domain/entities/vet.dart';

class VetModel extends Vet {
  const VetModel({
    required super.id,
    required super.name,
    super.phone,
    super.email,
    super.website,
    super.address,
    super.notes,
    super.createdAt,
    super.updatedAt,
  });

  factory VetModel.fromJson(Map<String, dynamic> json) {
    return VetModel(
      id: (json['id'] is int ? json['id'].toString() : json['id'] as String?) ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      website: json['website'] as String? ?? '',
      address: json['address'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  factory VetModel.fromEntity(Vet vet) {
    return VetModel(
      id: vet.id,
      name: vet.name,
      phone: vet.phone,
      email: vet.email,
      website: vet.website,
      address: vet.address,
      notes: vet.notes,
      createdAt: vet.createdAt,
      updatedAt: vet.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'website': website,
      'address': address,
      'notes': notes,
    };
  }
}
