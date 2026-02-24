import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/health_tracking/data/models/health_history_model.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_history_entry.dart';

void main() {
  group('HealthHistoryModel', () {
    test('fromJson creates model with all fields', () {
      final json = {
        'id': 'h1',
        'entry_id': 'entry-1',
        'taken_at': '2025-01-15T10:30:00.000',
        'notes': 'Administered successfully',
      };

      final model = HealthHistoryModel.fromJson(json);
      expect(model.id, 'h1');
      expect(model.entryId, 'entry-1');
      expect(model.takenAt, DateTime(2025, 1, 15, 10, 30));
      expect(model.notes, 'Administered successfully');
    });

    test('fromJson handles missing id', () {
      final json = {
        'entry_id': 'entry-1',
        'taken_at': '2025-01-15T10:30:00.000',
      };

      final model = HealthHistoryModel.fromJson(json);
      expect(model.id, '');
    });

    test('fromJson handles missing entry_id', () {
      final json = {
        'id': 'h1',
        'taken_at': '2025-01-15T10:30:00.000',
      };

      final model = HealthHistoryModel.fromJson(json);
      expect(model.entryId, '');
    });

    test('fromJson handles missing notes', () {
      final json = {
        'id': 'h1',
        'entry_id': 'entry-1',
        'taken_at': '2025-01-15T10:30:00.000',
      };

      final model = HealthHistoryModel.fromJson(json);
      expect(model.notes, '');
    });

    test('fromJson handles invalid taken_at', () {
      final json = {
        'id': 'h1',
        'entry_id': 'entry-1',
        'taken_at': 'invalid-date',
      };

      final model = HealthHistoryModel.fromJson(json);
      expect(model.takenAt, isA<DateTime>());
    });

    test('fromJson handles null values', () {
      final json = <String, dynamic>{
        'id': null,
        'entry_id': null,
        'taken_at': null,
        'notes': null,
      };

      final model = HealthHistoryModel.fromJson(json);
      expect(model.id, '');
      expect(model.entryId, '');
      expect(model.notes, '');
    });

    test('fromJson handles empty map', () {
      final model = HealthHistoryModel.fromJson({});
      expect(model.id, '');
      expect(model.entryId, '');
      expect(model.notes, '');
    });

    test('is a HealthHistoryEntry', () {
      final model = HealthHistoryModel.fromJson({
        'id': 'h1',
        'entry_id': 'entry-1',
        'taken_at': '2025-01-15T10:30:00.000',
      });

      expect(model, isA<HealthHistoryEntry>());
    });
  });
}
