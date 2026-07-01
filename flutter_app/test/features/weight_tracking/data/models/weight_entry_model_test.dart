import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/weight_tracking/data/models/weight_entry_model.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_entry.dart';

void main() {
  group('WeightEntryModel', () {
    final fullJson = {
      'id': 'w-1',
      'pet_id': 'pet-1',
      'date': '2025-06-15',
      'weight': 12.5,
      'notes': 'Post-diet weigh-in',
      'created_at': '2025-06-15T10:00:00.000Z',
    };

    test('fromJson parses all fields correctly', () {
      final model = WeightEntryModel.fromJson(fullJson);

      expect(model.id, 'w-1');
      expect(model.petId, 'pet-1');
      expect(model.date.year, 2025);
      expect(model.date.month, 6);
      expect(model.date.day, 15);
      expect(model.weight, 12.5);
      expect(model.notes, 'Post-diet weigh-in');
      expect(model.createdAt, isNotNull);
      expect(model.createdAt!.year, 2025);
    });

    test('fromJson handles int id coercion', () {
      final json = {...fullJson, 'id': 42};
      final model = WeightEntryModel.fromJson(json);
      expect(model.id, '42');
    });

    test('fromJson handles int pet_id coercion', () {
      final json = {...fullJson, 'pet_id': 7};
      final model = WeightEntryModel.fromJson(json);
      expect(model.petId, '7');
    });

    test('fromJson handles string weight', () {
      final json = {...fullJson, 'weight': '15.3'};
      final model = WeightEntryModel.fromJson(json);
      expect(model.weight, 15.3);
    });

    test('fromJson handles int weight', () {
      final json = {...fullJson, 'weight': 10};
      final model = WeightEntryModel.fromJson(json);
      expect(model.weight, 10.0);
    });

    test('fromJson defaults notes to empty string when null', () {
      final json = {...fullJson, 'notes': null};
      final model = WeightEntryModel.fromJson(json);
      expect(model.notes, '');
    });

    test('fromJson handles missing created_at', () {
      final json = Map<String, dynamic>.from(fullJson);
      json.remove('created_at');
      final model = WeightEntryModel.fromJson(json);
      expect(model.createdAt, isNull);
    });

    test('fromJson handles null id and pet_id', () {
      final json = {...fullJson, 'id': null, 'pet_id': null};
      final model = WeightEntryModel.fromJson(json);
      expect(model.id, '');
      expect(model.petId, '');
    });

    test('toJson produces correct map', () {
      final model = WeightEntryModel.fromJson(fullJson);
      final json = model.toJson();

      expect(json['id'], 'w-1');
      expect(json['pet_id'], 'pet-1');
      expect(json['date'], '2025-06-15');
      expect(json['weight'], 12.5);
      expect(json['notes'], 'Post-diet weigh-in');
    });

    test('toJson date format is YYYY-MM-DD', () {
      final model = WeightEntryModel.fromJson(fullJson);
      final json = model.toJson();
      expect(json['date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });

    test('toJson does not include created_at', () {
      final model = WeightEntryModel.fromJson(fullJson);
      final json = model.toJson();
      expect(json.containsKey('created_at'), isFalse);
    });

    test('fromEntity preserves all fields', () {
      final entity = WeightEntry(
        id: 'w-2',
        petId: 'pet-3',
        date: DateTime(2025, 5, 10),
        weight: 8.7,
        notes: 'Healthy weight',
        createdAt: DateTime(2025, 5, 10, 14, 30),
      );
      final model = WeightEntryModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.petId, entity.petId);
      expect(model.date, entity.date);
      expect(model.weight, entity.weight);
      expect(model.notes, entity.notes);
      expect(model.createdAt, entity.createdAt);
    });

    test('toJson round-trips through fromJson', () {
      final original = WeightEntryModel.fromJson(fullJson);
      final json = original.toJson();
      final restored = WeightEntryModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.petId, original.petId);
      expect(restored.weight, original.weight);
      expect(restored.notes, original.notes);
    });

    test('fromJson uses date portion of legacy UTC timestamp', () {
      final model = WeightEntryModel.fromJson({
        ...fullJson,
        'date': '2025-06-15T00:00:00.000Z',
      });
      expect(model.date.day, 15);
    });

    test('parses legacy space-separated date string', () {
      final model = WeightEntryModel.fromJson({
        ...fullJson,
        'date': '2025-06-15 00:00:00.000Z',
      });
      expect(model.date.day, 15);
    });

    test('is a WeightEntry', () {
      final model = WeightEntryModel.fromJson(fullJson);
      expect(model, isA<WeightEntry>());
    });
  });
}
