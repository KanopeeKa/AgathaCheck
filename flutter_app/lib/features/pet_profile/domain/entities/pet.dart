/// Represents a pet entity in the domain layer.
///
/// This is the core business object that holds all information
/// about a pet profile. It is immutable and contains no
/// serialization logic.
class Pet {
  /// Creates a new [Pet] instance.
  const Pet({
    required this.id,
    required this.name,
    required this.species,
    this.breed = '',
    this.age,
    this.weight,
    this.bio = '',
    this.photoPath,
    this.vetId,
  });

  final String id;
  final String name;
  final String species;
  final String breed;
  final double? age;
  final double? weight;
  final String bio;
  final String? photoPath;
  final String? vetId;

  Pet copyWith({
    String? id,
    String? name,
    String? species,
    String? breed,
    double? age,
    double? weight,
    String? bio,
    String? photoPath,
    String? vetId,
    bool clearVetId = false,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      bio: bio ?? this.bio,
      photoPath: photoPath ?? this.photoPath,
      vetId: clearVetId ? null : (vetId ?? this.vetId),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pet && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
