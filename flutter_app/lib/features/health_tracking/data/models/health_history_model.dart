import '../../domain/entities/health_history_entry.dart';

/// Data model for [HealthHistoryEntry] with JSON serialization.
class HealthHistoryModel extends HealthHistoryEntry {
  /// Creates a [HealthHistoryModel] instance.
  const HealthHistoryModel({
    required super.id,
    required super.entryId,
    required super.takenAt,
    super.notes,
  });

  /// Creates a [HealthHistoryModel] from a JSON map.
  factory HealthHistoryModel.fromJson(Map<String, dynamic> json) {
    return HealthHistoryModel(
      id: json['id'] as String? ?? '',
      entryId: json['entry_id'] as String? ?? '',
      takenAt: DateTime.tryParse(json['taken_at'] as String? ?? '') ??
          DateTime.now(),
      notes: json['notes'] as String? ?? '',
    );
  }
}
