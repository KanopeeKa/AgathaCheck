/// Private user-owned label for organizing visible pets.
class PetTag {
  const PetTag({required this.id, required this.name, this.petIds = const []});

  final String id;
  final String name;
  final List<String> petIds;

  PetTag copyWith({String? id, String? name, List<String>? petIds}) => PetTag(
    id: id ?? this.id,
    name: name ?? this.name,
    petIds: petIds ?? this.petIds,
  );
}

/// How multiple selected tags combine when filtering the pet list.
enum PetTagMatchMode { any, all }
