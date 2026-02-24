import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_entry_model.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';

void main() {
  group('HealthEntryModel', () {
    final testJson = {
      'id': 'abc-123',
      'pet_id': 'pet-1',
      'name': 'Heartgard',
      'type': 'medication',
      'dosage': '1 tablet',
      'frequency': 'monthly',
      'frequency_days': null,
      'start_date': '2025-01-01',
      'next_due_date': '2025-02-01T09:00:00.000Z',
      'notes': 'Give with food',
      'created_at': '2025-01-01T00:00:00.000Z',
      'updated_at': '2025-01-15T00:00:00.000Z',
    };

    test('fromJson parses all fields correctly', () {
      final model = HealthEntryModel.fromJson(testJson);
      expect(model.id, 'abc-123');
      expect(model.petId, 'pet-1');
      expect(model.name, 'Heartgard');
      expect(model.type, HealthEntryType.medication);
      expect(model.dosage, '1 tablet');
      expect(model.frequency, HealthFrequency.monthly);
      expect(model.frequencyDays, isNull);
      expect(model.notes, 'Give with food');
      expect(model.startDate.year, 2025);
      expect(model.startDate.month, 1);
      expect(model.startDate.day, 1);
      expect(model.nextDueDate.year, 2025);
      expect(model.nextDueDate.month, 2);
      expect(model.nextDueDate.day, 1);
    });

    test('fromJson handles missing optional fields', () {
      final minimalJson = {
        'id': 'x',
        'name': 'Test',
        'type': 'vaccine',
        'frequency': 'weekly',
        'start_date': '2025-06-01',
        'next_due_date': '2025-06-08T00:00:00.000Z',
      };
      final model = HealthEntryModel.fromJson(minimalJson);
      expect(model.petId, '');
      expect(model.dosage, '');
      expect(model.notes, '');
      expect(model.type, HealthEntryType.vaccine);
      expect(model.frequency, HealthFrequency.weekly);
    });

    test('fromJson defaults unknown type to medication', () {
      final json = {...testJson, 'type': 'unknown'};
      final model = HealthEntryModel.fromJson(json);
      expect(model.type, HealthEntryType.medication);
    });

    test('fromJson defaults unknown frequency to daily', () {
      final json = {...testJson, 'frequency': 'biweekly'};
      final model = HealthEntryModel.fromJson(json);
      expect(model.frequency, HealthFrequency.daily);
    });

    test('toJson produces correct map', () {
      final model = HealthEntryModel.fromJson(testJson);
      final json = model.toJson();
      expect(json['id'], 'abc-123');
      expect(json['pet_id'], 'pet-1');
      expect(json['name'], 'Heartgard');
      expect(json['type'], 'medication');
      expect(json['dosage'], '1 tablet');
      expect(json['frequency'], 'monthly');
      expect(json['notes'], 'Give with food');
    });

    test('fromEntity preserves all data', () {
      final entity = HealthEntry(
        id: 'e-1',
        petId: 'p-1',
        name: 'Rabies',
        type: HealthEntryType.vaccine,
        dosage: '1ml',
        frequency: HealthFrequency.custom,
        frequencyDays: 365,
        startDate: DateTime(2025, 3, 1),
        nextDueDate: DateTime(2026, 3, 1),
        notes: 'Annual',
      );
      final model = HealthEntryModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.name, entity.name);
      expect(model.type, entity.type);
      expect(model.frequencyDays, 365);
    });

    test('toJson round-trips through fromJson', () {
      final original = HealthEntryModel.fromJson(testJson);
      final json = original.toJson();
      final restored = HealthEntryModel.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.frequency, original.frequency);
    });

    test('fromJson parses all entry types', () {
      for (final t in ['medication', 'preventive', 'vaccine']) {
        final model = HealthEntryModel.fromJson({...testJson, 'type': t});
        expect(model.type.name, t);
      }
    });

    test('fromJson parses all frequencies', () {
      for (final f in ['daily', 'weekly', 'monthly', 'custom']) {
        final model =
            HealthEntryModel.fromJson({...testJson, 'frequency': f});
        expect(model.frequency.name, f);
      }
    });
  });
}
