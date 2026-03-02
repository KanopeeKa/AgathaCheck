class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.petId,
    required this.date,
    required this.weight,
    this.notes = '',
    this.createdAt,
  });

  final int id;
  final String petId;
  final DateTime date;
  final double weight;
  final String notes;
  final DateTime? createdAt;

  WeightEntry copyWith({
    int? id,
    String? petId,
    DateTime? date,
    double? weight,
    String? notes,
    DateTime? createdAt,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
