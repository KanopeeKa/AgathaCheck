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
    this.insurance = '',
    this.neuteredDate,
    this.neuterDismissed = false,
    this.chipId = '',
    this.chipDismissed = false,
    this.photoPath,
    this.vetId,
    this.colorValue,
    this.passedAway = false,
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
      insurance: (json['insurance'] as String?) ?? '',
      neuteredDate: json['neuteredDate'] != null
          ? DateTime.tryParse(json['neuteredDate'] as String)
          : null,
      neuterDismissed: json['neuterDismissed'] == true,
      chipId: (json['chipId'] as String?) ?? '',
      chipDismissed: json['chipDismissed'] == true,
      photoPath: json['photoPath'] as String?,
      vetId: json['vetId'] as String?,
      colorValue: json['colorValue'] as int?,
      passedAway: json['passedAway'] == true,
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
      insurance: pet.insurance,
      neuteredDate: pet.neuteredDate,
      neuterDismissed: pet.neuterDismissed,
      chipId: pet.chipId,
      chipDismissed: pet.chipDismissed,
      photoPath: pet.photoPath,
      vetId: pet.vetId,
      colorValue: pet.colorValue,
      passedAway: pet.passedAway,
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
  final String insurance;
  final DateTime? neuteredDate;
  final bool neuterDismissed;
  final String chipId;
  final bool chipDismissed;
  final String? photoPath;
  final String? vetId;
  final int? colorValue;
  final bool passedAway;

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
      'insurance': insurance,
      'neuteredDate': neuteredDate?.toIso8601String(),
      'neuterDismissed': neuterDismissed,
      'chipId': chipId,
      'chipDismissed': chipDismissed,
      'photoPath': photoPath,
      'vetId': vetId,
      'colorValue': colorValue,
      'passedAway': passedAway,
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
      insurance: insurance,
      neuteredDate: neuteredDate,
      neuterDismissed: neuterDismissed,
      chipId: chipId,
      chipDismissed: chipDismissed,
      photoPath: photoPath,
      vetId: vetId,
      colorValue: colorValue,
      passedAway: passedAway,
    );
  }
}
