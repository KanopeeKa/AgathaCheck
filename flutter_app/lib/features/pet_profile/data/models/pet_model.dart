import 'dart:convert';

import '../../domain/entities/pet.dart';
import '../../../../core/utils/calendar_date.dart';

class PetModel {
  const PetModel({
    required this.id,
    required this.name,
    required this.species,
    this.breed = '',
    this.dateOfBirth,
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
    this.isShared = false,
    this.isFoster = false,
    this.organizationId,
    this.organizationName,
    this.fosterPlacementStatus,
    this.fosterName,
    this.primaryHolderName,
    this.createdAt,
  });

  static DateTime? _parseTimestamp(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] as String,
      name: json['name'] as String,
      species: json['species'] as String,
      breed: (json['breed'] as String?) ?? '',
      dateOfBirth: parseCalendarDate(
        json['dateOfBirth'] ?? json['date_of_birth'],
      ),
      weight: (json['weight'] as num?)?.toDouble(),
      gender: json['gender'] as String?,
      bio: (json['bio'] as String?) ?? '',
      insurance: (json['insurance'] as String?) ?? '',
      neuteredDate: parseCalendarDate(json['neuteredDate']),
      neuterDismissed: json['neuterDismissed'] == true,
      chipId: (json['chipId'] as String?) ?? '',
      chipDismissed: json['chipDismissed'] == true,
      photoPath: json['photoPath'] as String?,
      vetId: json['vetId'] as String?,
      colorValue: json['colorValue'] as int?,
      passedAway: json['passedAway'] == true,
      isShared: json['is_shared'] == true,
      isFoster: json['is_foster'] == true,
      organizationId: json['organization_id']?.toString(),
      organizationName: json['organization_name'] as String?,
      fosterPlacementStatus: json['foster_placement_status'] as String?,
      fosterName: json['foster_name'] as String?,
      primaryHolderName:
          json['primary_holder_name'] as String? ??
          json['guardian_name'] as String?,
      createdAt: _parseTimestamp(json['createdAt'] ?? json['created_at']),
    );
  }

  factory PetModel.fromEntity(Pet pet) {
    return PetModel(
      id: pet.id,
      name: pet.name,
      species: pet.species,
      breed: pet.breed,
      dateOfBirth: pet.dateOfBirth,
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
      isShared: pet.isShared,
      isFoster: pet.isFoster,
      organizationId: pet.organizationId,
      organizationName: pet.organizationName,
      fosterPlacementStatus: pet.fosterPlacementStatus,
      fosterName: pet.fosterName,
      primaryHolderName: pet.primaryHolderName,
      createdAt: pet.createdAt,
    );
  }

  factory PetModel.fromJsonString(String jsonString) {
    return PetModel.fromJson(json.decode(jsonString) as Map<String, dynamic>);
  }

  final String id;
  final String name;
  final String species;
  final String breed;
  final DateTime? dateOfBirth;
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
  final bool isShared;
  final bool isFoster;
  final String? organizationId;
  final String? organizationName;
  final String? fosterPlacementStatus;
  final String? fosterName;
  final String? primaryHolderName;
  final DateTime? createdAt;

  Map<String, dynamic> toJson({bool includeWeightEntryDate = false}) {
    return {
      'id': id,
      'name': name,
      'species': species,
      'breed': breed,
      'dateOfBirth': toCalendarDateString(dateOfBirth),
      'weight': weight,
      'gender': gender,
      'bio': bio,
      'insurance': insurance,
      'neuteredDate': toCalendarDateString(neuteredDate),
      'neuterDismissed': neuterDismissed,
      'chipId': chipId,
      'chipDismissed': chipDismissed,
      'photoPath': photoPath,
      'vetId': vetId,
      'colorValue': colorValue,
      'passedAway': passedAway,
      'organization_id': organizationId,
      'organization_name': organizationName,
      if (includeWeightEntryDate && weight != null)
        'weightEntryDate': toCalendarDateString(
          calendarDateOnly(DateTime.now()),
        ),
    };
  }

  String toJsonString() => json.encode(toJson());

  Pet toEntity() {
    return Pet(
      id: id,
      name: name,
      species: species,
      breed: breed,
      dateOfBirth: dateOfBirth,
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
      isShared: isShared,
      isFoster: isFoster,
      organizationId: organizationId,
      organizationName: organizationName,
      fosterPlacementStatus: fosterPlacementStatus,
      fosterName: fosterName,
      primaryHolderName: primaryHolderName,
      createdAt: createdAt,
    );
  }
}
