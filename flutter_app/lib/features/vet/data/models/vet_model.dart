import '../../domain/entities/vet.dart';

/// Data model for veterinarian records with JSON serialization support.
///
/// Extends [Vet] to add serialization capabilities for communicating
/// with remote data sources. Handles conversion between JSON maps
/// and domain entities.
class VetModel extends Vet {
  /// Creates a new [VetModel] instance.
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

  /// Creates a [VetModel] from a JSON map.
  ///
  /// Handles type coercion for the `id` field (supports both [int] and
  /// [String]) and gracefully defaults missing or null fields to empty strings.
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

  /// Creates a [VetModel] from a [Vet] domain entity.
  ///
  /// Useful for converting domain objects into data models before
  /// sending them to the remote data source.
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

  /// Converts this [VetModel] to a JSON map for API requests.
  ///
  /// Only includes fields that are sent to the server;
  /// timestamps are excluded as they are managed server-side.
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
