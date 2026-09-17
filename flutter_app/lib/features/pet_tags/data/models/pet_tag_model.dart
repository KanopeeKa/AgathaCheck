import '../../domain/entities/pet_tag.dart';

class PetTagModel {
  const PetTagModel({
    required this.id,
    required this.name,
    required this.petIds,
  });

  final String id;
  final String name;
  final List<String> petIds;

  factory PetTagModel.fromJson(Map<String, dynamic> json) {
    final rawPetIds = json['pet_ids'];
    return PetTagModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      petIds: rawPetIds is List
          ? rawPetIds.map((id) => id.toString()).toList()
          : const [],
    );
  }

  PetTag toEntity() => PetTag(id: id, name: name, petIds: petIds);
}
