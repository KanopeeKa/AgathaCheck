import '../../domain/entities/weight_entry.dart';

class WeightEntryModel extends WeightEntry {
  const WeightEntryModel({
    required super.id,
    required super.petId,
    required super.date,
    required super.weight,
    super.notes,
    super.createdAt,
  });

  factory WeightEntryModel.fromJson(Map<String, dynamic> json) {
    return WeightEntryModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      petId: json['pet_id']?.toString() ?? '',
      date: DateTime.parse(json['date'].toString()),
      weight: (json['weight'] is num)
          ? (json['weight'] as num).toDouble()
          : double.parse(json['weight'].toString()),
      notes: json['notes']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'date': date.toIso8601String().split('T').first,
      'weight': weight,
      'notes': notes,
    };
  }

  factory WeightEntryModel.fromEntity(WeightEntry entry) {
    return WeightEntryModel(
      id: entry.id,
      petId: entry.petId,
      date: entry.date,
      weight: entry.weight,
      notes: entry.notes,
      createdAt: entry.createdAt,
    );
  }
}
