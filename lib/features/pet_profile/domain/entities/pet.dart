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
  });

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

  double? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    final diff = now.difference(dateOfBirth!).inDays;
    return diff / 365.25;
  }

  String? get ageDisplay {
    final a = age;
    if (a == null) return null;
    if (a < 1) {
      final months = (a * 12).round();
      return months <= 1 ? '1 month' : '$months months';
    }
    return '${a.toStringAsFixed(1)} yrs';
  }

  static const List<int> palette = [
    0xFF7E57C2, // deep purple
    0xFF26A69A, // teal
    0xFFEF5350, // red
    0xFF42A5F5, // blue
    0xFFFF7043, // deep orange
    0xFF66BB6A, // green
    0xFFAB47BC, // purple
    0xFFFFCA28, // amber
    0xFF26C6DA, // cyan
    0xFFEC407A, // pink
    0xFF8D6E63, // brown
    0xFF5C6BC0, // indigo
    0xFF9CCC65, // light green
    0xFFFF8A65, // light deep orange
    0xFF78909C, // blue grey
  ];

  static int pickColor(int index) {
    return palette[index % palette.length];
  }

  Pet copyWith({
    String? id,
    String? name,
    String? species,
    String? breed,
    DateTime? dateOfBirth,
    double? weight,
    String? gender,
    String? bio,
    String? insurance,
    DateTime? neuteredDate,
    bool? neuterDismissed,
    String? chipId,
    bool? chipDismissed,
    String? photoPath,
    String? vetId,
    int? colorValue,
    bool? passedAway,
    bool clearVetId = false,
    bool clearGender = false,
    bool clearNeuteredDate = false,
    bool clearDateOfBirth = false,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      dateOfBirth: clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
      weight: weight ?? this.weight,
      gender: clearGender ? null : (gender ?? this.gender),
      bio: bio ?? this.bio,
      insurance: insurance ?? this.insurance,
      neuteredDate: clearNeuteredDate ? null : (neuteredDate ?? this.neuteredDate),
      neuterDismissed: neuterDismissed ?? this.neuterDismissed,
      chipId: chipId ?? this.chipId,
      chipDismissed: chipDismissed ?? this.chipDismissed,
      photoPath: photoPath ?? this.photoPath,
      vetId: clearVetId ? null : (vetId ?? this.vetId),
      colorValue: colorValue ?? this.colorValue,
      passedAway: passedAway ?? this.passedAway,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pet && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
