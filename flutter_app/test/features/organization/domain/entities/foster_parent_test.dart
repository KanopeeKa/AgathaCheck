import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_parent.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';

void main() {
  group('FosterParentAssignedPet.fromJson', () {
    test('parses pet assignment fields', () {
      final pet = FosterParentAssignedPet.fromJson({
        'pet_id': 'pet-1',
        'pet_name': 'Max',
        'status': 'in_progress',
      });

      expect(pet.petId, 'pet-1');
      expect(pet.petName, 'Max');
      expect(pet.status, 'in_progress');
    });

    test('defaults missing fields to empty strings', () {
      final pet = FosterParentAssignedPet.fromJson({});

      expect(pet.petId, '');
      expect(pet.petName, '');
      expect(pet.status, '');
    });
  });

  group('FosterParent.fromJson', () {
    test('parses member foster parent with active pets', () {
      final parent = FosterParent.fromJson({
        'id': 'ou-1',
        'kind': 'member',
        'user_id': 'user-1',
        'display_name': 'Jane Foster',
        'email': 'jane@example.com',
        'phone': '555-1234',
        'notes': 'Great foster',
        'role': 'associate',
        'photo_url': '/photos/jane.jpg',
        'active_pet_count': 2,
        'active_pets': [
          {'pet_id': 'pet-a', 'pet_name': 'Max', 'status': 'in_progress'},
        ],
      });

      expect(parent.id, 'ou-1');
      expect(parent.kind, FosterParentKind.member);
      expect(parent.userId, 'user-1');
      expect(parent.displayName, 'Jane Foster');
      expect(parent.email, 'jane@example.com');
      expect(parent.phone, '555-1234');
      expect(parent.notes, 'Great foster');
      expect(parent.role, OrgMemberRole.associate);
      expect(parent.photoUrl, '/photos/jane.jpg');
      expect(parent.activePetCount, 2);
      expect(parent.activePets, hasLength(1));
      expect(parent.activePets.first.petName, 'Max');
      expect(parent.isMember, isTrue);
      expect(parent.isExternal, isFalse);
    });

    test('parses external foster parent', () {
      final parent = FosterParent.fromJson({
        'id': 'fp-1',
        'kind': 'external',
        'display_name': 'Off-app Parent',
        'email': 'off@example.com',
        'active_pet_count': '0',
      });

      expect(parent.kind, FosterParentKind.external);
      expect(parent.userId, isNull);
      expect(parent.role, isNull);
      expect(parent.activePetCount, 0);
      expect(parent.isExternal, isTrue);
      expect(parent.isMember, isFalse);
    });

    test('defaults unknown kind to member', () {
      final parent = FosterParent.fromJson({'kind': 'unknown'});
      expect(parent.kind, FosterParentKind.member);
    });
  });

  group('FosterParent.initials', () {
    test('returns first and last initials for two-word name', () {
      const parent = FosterParent(
        id: '1',
        kind: FosterParentKind.member,
        displayName: 'Jane Foster',
      );
      expect(parent.initials, 'JF');
    });

    test('returns single initial for one-word name', () {
      const parent = FosterParent(
        id: '1',
        kind: FosterParentKind.external,
        displayName: 'Madonna',
      );
      expect(parent.initials, 'M');
    });

    test('returns question mark for empty name', () {
      const parent = FosterParent(
        id: '1',
        kind: FosterParentKind.external,
        displayName: '   ',
      );
      expect(parent.initials, '?');
    });
  });

  group('FosterParentKind wire format', () {
    test('round-trips external kind', () {
      expect(FosterParentKind.fromWire('external'), FosterParentKind.external);
      expect(FosterParentKind.external.toWire(), 'external');
    });

    test('defaults unknown wire value to member', () {
      expect(FosterParentKind.fromWire('bogus').toWire(), 'member');
    });
  });
}
