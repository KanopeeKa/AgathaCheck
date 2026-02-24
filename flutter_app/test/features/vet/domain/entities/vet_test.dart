import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/vet/domain/entities/vet.dart';

void main() {
  const testVet = Vet(
    id: 'vet-1',
    name: 'Dr. Smith',
    phone: '555-1234',
    email: 'smith@vet.com',
    website: 'https://drsmith.com',
    address: '123 Main St',
    notes: 'Specializes in dogs',
    createdAt: null,
    updatedAt: null,
  );

  group('Vet entity', () {
    test('should create Vet with all fields', () {
      expect(testVet.id, 'vet-1');
      expect(testVet.name, 'Dr. Smith');
      expect(testVet.phone, '555-1234');
      expect(testVet.email, 'smith@vet.com');
      expect(testVet.website, 'https://drsmith.com');
      expect(testVet.address, '123 Main St');
      expect(testVet.notes, 'Specializes in dogs');
      expect(testVet.createdAt, isNull);
      expect(testVet.updatedAt, isNull);
    });

    test('should use default values for optional fields', () {
      const vet = Vet(id: 'vet-2', name: 'Dr. Jones');
      expect(vet.phone, '');
      expect(vet.email, '');
      expect(vet.website, '');
      expect(vet.address, '');
      expect(vet.notes, '');
      expect(vet.createdAt, isNull);
      expect(vet.updatedAt, isNull);
    });

    test('should create Vet with DateTime fields', () {
      final now = DateTime.now();
      final vet = Vet(
        id: 'vet-3',
        name: 'Dr. Lee',
        createdAt: now,
        updatedAt: now,
      );
      expect(vet.createdAt, now);
      expect(vet.updatedAt, now);
    });
  });

  group('copyWith', () {
    test('should return a copy with updated name', () {
      final copy = testVet.copyWith(name: 'Dr. Brown');
      expect(copy.name, 'Dr. Brown');
      expect(copy.id, testVet.id);
      expect(copy.phone, testVet.phone);
    });

    test('should return a copy with updated id', () {
      final copy = testVet.copyWith(id: 'new-id');
      expect(copy.id, 'new-id');
      expect(copy.name, testVet.name);
    });

    test('should return a copy with all fields updated', () {
      final now = DateTime.now();
      final copy = testVet.copyWith(
        id: 'new-id',
        name: 'New Name',
        phone: '999',
        email: 'new@email.com',
        website: 'https://new.com',
        address: '456 Elm St',
        notes: 'New notes',
        createdAt: now,
        updatedAt: now,
      );
      expect(copy.id, 'new-id');
      expect(copy.name, 'New Name');
      expect(copy.phone, '999');
      expect(copy.email, 'new@email.com');
      expect(copy.website, 'https://new.com');
      expect(copy.address, '456 Elm St');
      expect(copy.notes, 'New notes');
      expect(copy.createdAt, now);
      expect(copy.updatedAt, now);
    });

    test('should retain original values when no arguments passed', () {
      final copy = testVet.copyWith();
      expect(copy.id, testVet.id);
      expect(copy.name, testVet.name);
      expect(copy.phone, testVet.phone);
      expect(copy.email, testVet.email);
      expect(copy.website, testVet.website);
      expect(copy.address, testVet.address);
      expect(copy.notes, testVet.notes);
    });
  });

  group('equality', () {
    test('should be equal when ids match', () {
      const vet1 = Vet(id: 'vet-1', name: 'Dr. Smith');
      const vet2 = Vet(id: 'vet-1', name: 'Different Name');
      expect(vet1, equals(vet2));
    });

    test('should not be equal when ids differ', () {
      const vet1 = Vet(id: 'vet-1', name: 'Dr. Smith');
      const vet2 = Vet(id: 'vet-2', name: 'Dr. Smith');
      expect(vet1, isNot(equals(vet2)));
    });

    test('should be equal to itself', () {
      expect(testVet, equals(testVet));
    });

    test('should not be equal to non-Vet object', () {
      // ignore: unrelated_type_equality_checks
      expect(testVet == 'not a vet', isFalse);
    });
  });

  group('hashCode', () {
    test('should have same hashCode for same id', () {
      const vet1 = Vet(id: 'vet-1', name: 'Dr. Smith');
      const vet2 = Vet(id: 'vet-1', name: 'Different');
      expect(vet1.hashCode, equals(vet2.hashCode));
    });

    test('should have different hashCode for different ids', () {
      const vet1 = Vet(id: 'vet-1', name: 'Dr. Smith');
      const vet2 = Vet(id: 'vet-2', name: 'Dr. Smith');
      expect(vet1.hashCode, isNot(equals(vet2.hashCode)));
    });
  });
}
