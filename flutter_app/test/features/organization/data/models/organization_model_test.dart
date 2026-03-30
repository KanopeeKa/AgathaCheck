import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/data/models/organization_model.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';

void main() {
  group('OrganizationModel', () {
    final fullJson = {
      'id': 'org-1',
      'name': 'Happy Paws Rescue',
      'type': 'charity',
      'email': 'info@happypaws.org',
      'phone': '+44 1234 567890',
      'address': '123 Rescue Lane',
      'website': 'https://happypaws.org',
      'bio': 'We rescue animals',
      'photo_url': '/photos/org.jpg',
      'created_by': 'user-1',
      'role': 'super_user',
      'member_count': 5,
      'pet_count': 12,
      'created_at': '2025-01-01T00:00:00.000Z',
      'updated_at': '2025-06-01T00:00:00.000Z',
    };

    test('fromJson parses all fields correctly', () {
      final model = OrganizationModel.fromJson(fullJson);

      expect(model.id, 'org-1');
      expect(model.name, 'Happy Paws Rescue');
      expect(model.type, OrganizationType.charity);
      expect(model.email, 'info@happypaws.org');
      expect(model.phone, '+44 1234 567890');
      expect(model.address, '123 Rescue Lane');
      expect(model.website, 'https://happypaws.org');
      expect(model.bio, 'We rescue animals');
      expect(model.photoUrl, '/photos/org.jpg');
      expect(model.createdBy, 'user-1');
      expect(model.role, 'super_user');
      expect(model.memberCount, 5);
      expect(model.petCount, 12);
      expect(model.createdAt, isNotNull);
      expect(model.createdAt!.year, 2025);
      expect(model.updatedAt, isNotNull);
    });

    test('fromJson parses professional type', () {
      final json = {...fullJson, 'type': 'professional'};
      final model = OrganizationModel.fromJson(json);
      expect(model.type, OrganizationType.professional);
    });

    test('fromJson defaults unknown type to professional', () {
      final json = {...fullJson, 'type': 'unknown'};
      final model = OrganizationModel.fromJson(json);
      expect(model.type, OrganizationType.professional);
    });

    test('fromJson handles int id coercion', () {
      final json = {...fullJson, 'id': 42};
      final model = OrganizationModel.fromJson(json);
      expect(model.id, '42');
    });

    test('fromJson handles string member_count', () {
      final json = {...fullJson, 'member_count': '10'};
      final model = OrganizationModel.fromJson(json);
      expect(model.memberCount, 10);
    });

    test('fromJson handles string pet_count', () {
      final json = {...fullJson, 'pet_count': '3'};
      final model = OrganizationModel.fromJson(json);
      expect(model.petCount, 3);
    });

    test('fromJson handles null/missing optional fields with defaults', () {
      final json = <String, dynamic>{
        'id': 'org-2',
        'name': 'Min Org',
        'type': 'professional',
      };
      final model = OrganizationModel.fromJson(json);

      expect(model.email, '');
      expect(model.phone, '');
      expect(model.address, '');
      expect(model.website, '');
      expect(model.bio, '');
      expect(model.photoUrl, '');
      expect(model.createdBy, isNull);
      expect(model.role, 'member');
      expect(model.memberCount, 0);
      expect(model.petCount, 0);
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });

    test('fromJson handles null values gracefully', () {
      final json = {
        'id': null,
        'name': null,
        'type': null,
        'email': null,
        'phone': null,
        'address': null,
        'website': null,
        'bio': null,
        'photo_url': null,
        'created_by': null,
        'role': null,
        'member_count': null,
        'pet_count': null,
        'created_at': null,
        'updated_at': null,
      };
      final model = OrganizationModel.fromJson(json);

      expect(model.id, '');
      expect(model.name, '');
      expect(model.type, OrganizationType.professional);
      expect(model.email, '');
      expect(model.phone, '');
      expect(model.memberCount, 0);
      expect(model.petCount, 0);
    });

    test('toJson produces correct map', () {
      final model = OrganizationModel.fromJson(fullJson);
      final json = model.toJson();

      expect(json['id'], 'org-1');
      expect(json['name'], 'Happy Paws Rescue');
      expect(json['type'], 'charity');
      expect(json['email'], 'info@happypaws.org');
      expect(json['phone'], '+44 1234 567890');
      expect(json['address'], '123 Rescue Lane');
      expect(json['website'], 'https://happypaws.org');
      expect(json['bio'], 'We rescue animals');
      expect(json['photo_url'], '/photos/org.jpg');
      expect(json['created_by'], 'user-1');
    });

    test('toJson serializes professional type correctly', () {
      final json = {...fullJson, 'type': 'professional'};
      final model = OrganizationModel.fromJson(json);
      final output = model.toJson();
      expect(output['type'], 'professional');
    });

    test('toJson serializes charity type correctly', () {
      final model = OrganizationModel.fromJson(fullJson);
      final output = model.toJson();
      expect(output['type'], 'charity');
    });

    test('toJson omits created_by when null', () {
      final json = Map<String, dynamic>.from(fullJson);
      json.remove('created_by');
      final model = OrganizationModel.fromJson(json);
      final output = model.toJson();
      expect(output.containsKey('created_by'), isFalse);
    });

    test('fromEntity preserves all fields', () {
      final org = Organization(
        id: 'org-3',
        name: 'Vet Group',
        type: OrganizationType.professional,
        email: 'vet@group.com',
        phone: '555-0000',
        address: '456 Vet St',
        website: 'https://vetgroup.com',
        bio: 'Professional vets',
        photoUrl: '/photos/vet.jpg',
        createdBy: 'user-5',
        role: 'admin',
        memberCount: 3,
        petCount: 20,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 1),
      );
      final model = OrganizationModel.fromEntity(org);

      expect(model.id, org.id);
      expect(model.name, org.name);
      expect(model.type, org.type);
      expect(model.email, org.email);
      expect(model.phone, org.phone);
      expect(model.address, org.address);
      expect(model.website, org.website);
      expect(model.bio, org.bio);
      expect(model.photoUrl, org.photoUrl);
      expect(model.createdBy, org.createdBy);
      expect(model.role, org.role);
      expect(model.memberCount, org.memberCount);
      expect(model.petCount, org.petCount);
      expect(model.createdAt, org.createdAt);
      expect(model.updatedAt, org.updatedAt);
    });

    test('isSuperUser returns true for super_user role', () {
      final model = OrganizationModel.fromJson(fullJson);
      expect(model.isSuperUser, isTrue);
    });

    test('isSuperUser returns false for member role', () {
      final json = {...fullJson, 'role': 'member'};
      final model = OrganizationModel.fromJson(json);
      expect(model.isSuperUser, isFalse);
    });

    test('toJson round-trips through fromJson', () {
      final original = OrganizationModel.fromJson(fullJson);
      final json = original.toJson();
      final restored = OrganizationModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.email, original.email);
      expect(restored.phone, original.phone);
      expect(restored.bio, original.bio);
      expect(restored.photoUrl, original.photoUrl);
    });

    test('is an Organization', () {
      final model = OrganizationModel.fromJson(fullJson);
      expect(model, isA<Organization>());
    });
  });
}
