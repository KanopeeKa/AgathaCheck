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
  });

  /// Unique identifier for the pet.
  final String id;

  /// The pet's name.
  final String name;

  /// The species of the pet (e.g., Dog, Cat, Bird).
  final String species;

  /// The breed of the pet.
  final String breed;

  /// The age of the pet in years.
  final double? age;

  /// The weight of the pet in kilograms.
  final double? weight;

  /// A short biography or description of the pet.
  final String bio;

  /// File path or base64 string for the pet's photo.
  final String? photoPath;

  /// Creates a copy of this pet with the given fields replaced.
  Pet copyWith({
    String? id,
    String? name,
    String? species,
    String? breed,
    double? age,
    double? weight,
    String? bio,
    String? photoPath,
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
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pet && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
