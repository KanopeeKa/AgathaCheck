import 'package:flutter_test/flutter_test.dart';
import 'package:AgathaCheck/flutter_app/lib/features/auth/data/auth_service.dart';

void main() {
  group('AuthUser.fromJson', () {
    test('parses minimal user response (id and email only)', () {
      final json = {'id': '1', 'email': 'test@example.com'};
      final user = AuthUser.fromJson(json);
      expect(user.id, '1');
      expect(user.email, 'test@example.com');
      expect(user.firstName, isNull);
      expect(user.lastName, isNull);
      expect(user.category, isNull);
      expect(user.bio, isNull);
      expect(user.photoUrl, isNull);
      expect(user.createdAt, isNull);
      expect(user.updatedAt, isNull);
    });

    test('parses full user response', () {
      final json = {
        'id': '2',
        'email': 'full@example.com',
        'first_name': 'Full',
        'last_name': 'Name',
        'category': 'admin',
        'bio': 'Bio',
        'photo_url': 'http://example.com/photo.jpg',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
      };
      final user = AuthUser.fromJson(json);
      expect(user.id, '2');
      expect(user.email, 'full@example.com');
      expect(user.firstName, 'Full');
      expect(user.lastName, 'Name');
      expect(user.category, 'admin');
      expect(user.bio, 'Bio');
      expect(user.photoUrl, 'http://example.com/photo.jpg');
      expect(user.createdAt, '2024-01-01T00:00:00Z');
      expect(user.updatedAt, '2024-01-02T00:00:00Z');
    });

    test('handles non-string values gracefully', () {
      final json = {
        'id': 3,
        'email': 123,
        'first_name': 456,
        'last_name': {},
        'category': [],
        'bio': null,
        'photo_url': null,
        'created_at': null,
        'updated_at': null,
      };
      final user = AuthUser.fromJson(json);
      expect(user.id, '3');
      expect(user.email, '123');
      expect(user.firstName, '456');
      expect(user.lastName, '{}');
      expect(user.category, '[]');
      expect(user.bio, isNull);
      expect(user.photoUrl, isNull);
      expect(user.createdAt, isNull);
      expect(user.updatedAt, isNull);
    });
  });
}
