import '../../../../core/utils/calendar_date.dart';
import '../../../../core/weight/weight_unit.dart';
import '../../domain/entities/weight_entry.dart';
import '../../domain/entities/weight_fulfils.dart';

class WeightEntryModel extends WeightEntry {
  const WeightEntryModel({
    required super.id,
    required super.petId,
    required super.date,
    required super.weight,
    super.notes,
    super.createdAt,
    super.healthOccurrenceId,
    super.measurementSource,
    super.fulfils,
  });

  factory WeightEntryModel.fromJson(Map<String, dynamic> json) {
    final parsed = parseCalendarDate(json['date']);
    var weightKg = (json['weight'] is num)
        ? (json['weight'] as num).toDouble()
        : double.parse(json['weight'].toString());
    final wireUnit = json['unit']?.toString();
    if (wireUnit == 'lb') {
      weightKg = toKg(weightKg, WeightUnit.lb);
    }

    WeightFulfils? fulfils;
    final fulfilsJson = json['fulfils'];
    if (fulfilsJson is Map<String, dynamic>) {
      final scheduled = parseCalendarDate(fulfilsJson['scheduled_date']);
      fulfils = WeightFulfils(
        entryId: fulfilsJson['entry_id']?.toString() ?? '',
        entryName: fulfilsJson['entry_name']?.toString() ?? '',
        occurrenceId: fulfilsJson['occurrence_id']?.toString() ?? '',
        scheduledDate: calendarDateOnly(scheduled ?? DateTime.now()),
      );
    }

    return WeightEntryModel(
      id: json['id']?.toString() ?? '',
      petId: json['pet_id']?.toString() ?? '',
      date: calendarDateOnly(parsed ?? DateTime.now()),
      weight: weightKg,
      notes: json['notes']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : null,
      healthOccurrenceId: json['health_occurrence_id']?.toString(),
      measurementSource: json['measurement_source']?.toString() ?? 'guardian',
      fulfils: fulfils,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'date': toCalendarDateString(calendarDateOnly(date)),
      'weight': weight,
      'unit': 'kg',
      'notes': notes,
    };
  }

  factory WeightEntryModel.fromEntity(WeightEntry entry) {
    return WeightEntryModel(
      id: entry.id,
      petId: entry.petId,
      date: calendarDateOnly(entry.date),
      weight: entry.weight,
      notes: entry.notes,
      createdAt: entry.createdAt,
      healthOccurrenceId: entry.healthOccurrenceId,
      measurementSource: entry.measurementSource,
      fulfils: entry.fulfils,
    );
  }
}
