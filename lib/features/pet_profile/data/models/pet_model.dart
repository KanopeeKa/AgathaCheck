import 'dart:convert';

import '../../domain/entities/pet.dart';

/// Data model for [Pet] with JSON serialization support.
///
/// Extends the domain [Pet] entity with the ability to convert
/// to and from JSON for local storage persistence.
class PetModel {
  /// Creates a [PetModel] from individual field values.
  const PetModel({
    required this.id,
    required this.name,
    required this.species,
    this.breed = '',
    this.age,
    this.weight,
    this.bio = '',
    this.photoPath,
  });

  /// Creates a [PetModel] from a JSON map.
  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] as String,
      name: json['name'] as String,
      species: json['species'] as String,
      breed: (json['breed'] as String?) ?? '',
      age: (json['age'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      bio: (json['bio'] as String?) ?? '',
      photoPath: json['photoPath'] as String?,
    );
  }

  /// Creates a [PetModel] from a domain [Pet] entity.
  factory PetModel.fromEntity(Pet pet) {
    return PetModel(
      id: pet.id,
      name: pet.name,
      species: pet.species,
      breed: pet.breed,
      age: pet.age,
      weight: pet.weight,
      bio: pet.bio,
      photoPath: pet.photoPath,
    );
  }

  /// Creates a [PetModel] from a JSON string.
  factory PetModel.fromJsonString(String jsonString) {
    return PetModel.fromJson(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }

  final String id;
  final String name;
  final String species;
  final String breed;
  final double? age;
  final double? weight;
  final String bio;
  final String? photoPath;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'breed': breed,
      'age': age,
      'weight': weight,
      'bio': bio,
      'photoPath': photoPath,
    };
  }

  /// Converts this model to a JSON string.
  String toJsonString() => json.encode(toJson());

  /// Converts this model to a domain [Pet] entity.
  Pet toEntity() {
    return Pet(
      id: id,
      name: name,
      species: species,
      breed: breed,
      age: age,
      weight: weight,
      bio: bio,
      photoPath: photoPath,
    );
  }
}
