import 'dart:convert';

import '../../domain/entities/pet.dart';

/// Data model for [Pet] with JSON serialization support.
///
/// Extends the domain [Pet] entity with the ability to convert
/// to and from JSON for local storage persistence.
class PetModel {
  const PetModel({
    required this.id,
    required this.name,
    required this.species,
    this.breed = '',
    this.age,
    this.weight,
    this.gender,
    this.bio = '',
    this.photoPath,
    this.vetId,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] as String,
      name: json['name'] as String,
      species: json['species'] as String,
      breed: (json['breed'] as String?) ?? '',
      age: (json['age'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      gender: json['gender'] as String?,
      bio: (json['bio'] as String?) ?? '',
      photoPath: json['photoPath'] as String?,
      vetId: json['vetId'] as String?,
    );
  }

  factory PetModel.fromEntity(Pet pet) {
    return PetModel(
      id: pet.id,
      name: pet.name,
      species: pet.species,
      breed: pet.breed,
      age: pet.age,
      weight: pet.weight,
      gender: pet.gender,
      bio: pet.bio,
      photoPath: pet.photoPath,
      vetId: pet.vetId,
    );
  }

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
  final String? gender;
  final String bio;
  final String? photoPath;
  final String? vetId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'breed': breed,
      'age': age,
      'weight': weight,
      'gender': gender,
      'bio': bio,
      'photoPath': photoPath,
      'vetId': vetId,
    };
  }

  String toJsonString() => json.encode(toJson());

  Pet toEntity() {
    return Pet(
      id: id,
      name: name,
      species: species,
      breed: breed,
      age: age,
      weight: weight,
      gender: gender,
      bio: bio,
      photoPath: photoPath,
      vetId: vetId,
    );
  }
}
