import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/health_tracking/data/models/health_history_model.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_history_entry.dart';

void main() {
  group('HealthHistoryModel', () {
    test('fromJson creates model with all fields', () {
      final json = {
        'id': 'h1',
        'health_entry_id': 'entry-1',
        'changed_at': '2025-01-15T10:30:00.000',
        'due_date': '2025-01-14',
        'completed_on': '2025-01-15',
        'marked_by_name': 'Jane',
        'notes': 'Administered successfully',
      };

      final model = HealthHistoryModel.fromJson(json);
      expect(model.id, 'h1');
      expect(model.entryId, 'entry-1');
      expect(model.markedAt, DateTime(2025, 1, 15, 10, 30));
      expect(model.takenAt, DateTime(2025, 1, 15, 10, 30));
      expect(model.dueDate, DateTime(2025, 1, 14));
      expect(model.completedOn, DateTime(2025, 1, 15));
      expect(model.markedByName, 'Jane');
      expect(model.notes, 'Administered successfully');
    });

    test('fromJson handles legacy taken_at alias', () {
      final json = {
        'id': 'h1',
        'entry_id': 'entry-1',
        'taken_at': '2025-01-15T10:30:00.000',
      };

      final model = HealthHistoryModel.fromJson(json);
      expect(model.entryId, 'entry-1');
      expect(model.markedAt, DateTime(2025, 1, 15, 10, 30));
    });

    test('fromJson handles missing id', () {
      final model = HealthHistoryModel.fromJson({
        'health_entry_id': 'entry-1',
        'changed_at': '2025-01-15T10:30:00.000',
      });
      expect(model.id, '');
    });

    test('fromJson handles missing notes', () {
      final model = HealthHistoryModel.fromJson({
        'id': 'h1',
        'health_entry_id': 'entry-1',
        'changed_at': '2025-01-15T10:30:00.000',
      });
      expect(model.notes, '');
    });

    test('fromJson handles invalid marked_at', () {
      final model = HealthHistoryModel.fromJson({
        'id': 'h1',
        'health_entry_id': 'entry-1',
        'changed_at': 'invalid-date',
      });
      expect(model.markedAt, isA<DateTime>());
    });

    test('is a HealthHistoryEntry', () {
      final model = HealthHistoryModel.fromJson({
        'id': 'h1',
        'health_entry_id': 'entry-1',
        'changed_at': '2025-01-15T10:30:00.000',
      });

      expect(model, isA<HealthHistoryEntry>());
    });
  });
}
