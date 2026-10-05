import 'weight_fulfils.dart';

class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.petId,
    required this.date,
    required this.weight,
    this.notes = '',
    this.createdAt,
    this.healthOccurrenceId,
    this.measurementSource = 'guardian',
    this.fulfils,
  });

  final String id;
  final String petId;
  final DateTime date;

  /// Stored in kg.
  final double weight;
  final String notes;
  final DateTime? createdAt;
  final String? healthOccurrenceId;
  final String measurementSource;
  final WeightFulfils? fulfils;

  WeightEntry copyWith({
    String? id,
    String? petId,
    DateTime? date,
    double? weight,
    String? notes,
    DateTime? createdAt,
    String? healthOccurrenceId,
    String? measurementSource,
    WeightFulfils? fulfils,
    bool clearFulfils = false,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      healthOccurrenceId: healthOccurrenceId ?? this.healthOccurrenceId,
      measurementSource: measurementSource ?? this.measurementSource,
      fulfils: clearFulfils ? null : (fulfils ?? this.fulfils),
    );
  }
}
