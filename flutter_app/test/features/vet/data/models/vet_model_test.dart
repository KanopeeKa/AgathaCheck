import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/vet/data/models/vet_model.dart';
import 'package:pet_profile_app/features/vet/domain/entities/vet.dart';

void main() {
  group('VetModel.fromJson', () {
    test('should create VetModel from valid JSON', () {
      final json = {
        'id': 'vet-1',
        'name': 'Dr. Smith',
        'phone': '555-1234',
        'email': 'smith@vet.com',
        'website': 'https://drsmith.com',
        'address': '123 Main St',
        'notes': 'Specializes in dogs',
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-02T00:00:00.000Z',
      };

      final model = VetModel.fromJson(json);

      expect(model.id, 'vet-1');
      expect(model.name, 'Dr. Smith');
      expect(model.phone, '555-1234');
      expect(model.email, 'smith@vet.com');
      expect(model.website, 'https://drsmith.com');
      expect(model.address, '123 Main St');
      expect(model.notes, 'Specializes in dogs');
      expect(model.createdAt, DateTime.utc(2025, 1, 1));
      expect(model.updatedAt, DateTime.utc(2025, 1, 2));
    });

    test('should handle int id', () {
      final json = {
        'id': 42,
        'name': 'Dr. Smith',
      };

      final model = VetModel.fromJson(json);
      expect(model.id, '42');
    });

    test('should handle missing fields with defaults', () {
      final json = <String, dynamic>{};

      final model = VetModel.fromJson(json);

      expect(model.id, '');
      expect(model.name, '');
      expect(model.phone, '');
      expect(model.email, '');
      expect(model.website, '');
      expect(model.address, '');
      expect(model.notes, '');
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });

    test('should handle null values', () {
      final json = {
        'id': null,
        'name': null,
        'phone': null,
        'email': null,
        'website': null,
        'address': null,
        'notes': null,
        'created_at': null,
        'updated_at': null,
      };

      final model = VetModel.fromJson(json);

      expect(model.id, '');
      expect(model.name, '');
      expect(model.phone, '');
      expect(model.email, '');
      expect(model.website, '');
      expect(model.address, '');
      expect(model.notes, '');
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });

    test('should handle invalid date strings', () {
      final json = {
        'id': 'vet-1',
        'name': 'Dr. Smith',
        'created_at': 'not-a-date',
        'updated_at': 'also-not-a-date',
      };

      final model = VetModel.fromJson(json);
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });
  });

  group('VetModel.toJson', () {
    test('should convert to JSON map', () {
      const model = VetModel(
        id: 'vet-1',
        name: 'Dr. Smith',
        phone: '555-1234',
        email: 'smith@vet.com',
        website: 'https://drsmith.com',
        address: '123 Main St',
        notes: 'Specializes in dogs',
      );

      final json = model.toJson();

      expect(json['id'], 'vet-1');
      expect(json['name'], 'Dr. Smith');
      expect(json['phone'], '555-1234');
      expect(json['email'], 'smith@vet.com');
      expect(json['website'], 'https://drsmith.com');
      expect(json['address'], '123 Main St');
      expect(json['notes'], 'Specializes in dogs');
    });

    test('should not include created_at and updated_at in JSON', () {
      final now = DateTime.now();
      final model = VetModel(
        id: 'vet-1',
        name: 'Dr. Smith',
        createdAt: now,
        updatedAt: now,
      );

      final json = model.toJson();
      expect(json.containsKey('created_at'), isFalse);
      expect(json.containsKey('updated_at'), isFalse);
    });
  });

  group('VetModel.fromEntity', () {
    test('should create VetModel from Vet entity', () {
      final now = DateTime.now();
      final vet = Vet(
        id: 'vet-1',
        name: 'Dr. Smith',
        phone: '555-1234',
        email: 'smith@vet.com',
        website: 'https://drsmith.com',
        address: '123 Main St',
        notes: 'Specializes in dogs',
        createdAt: now,
        updatedAt: now,
      );

      final model = VetModel.fromEntity(vet);

      expect(model.id, vet.id);
      expect(model.name, vet.name);
      expect(model.phone, vet.phone);
      expect(model.email, vet.email);
      expect(model.website, vet.website);
      expect(model.address, vet.address);
      expect(model.notes, vet.notes);
      expect(model.createdAt, vet.createdAt);
      expect(model.updatedAt, vet.updatedAt);
    });

    test('should create VetModel from minimal Vet entity', () {
      const vet = Vet(id: 'vet-2', name: 'Dr. Jones');

      final model = VetModel.fromEntity(vet);

      expect(model.id, 'vet-2');
      expect(model.name, 'Dr. Jones');
      expect(model.phone, '');
      expect(model.email, '');
    });
  });

  group('VetModel is a Vet', () {
    test('should be an instance of Vet', () {
      const model = VetModel(id: 'vet-1', name: 'Dr. Smith');
      expect(model, isA<Vet>());
    });
  });
}
