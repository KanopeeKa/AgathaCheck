import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/org_person.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';

void main() {
  group('OrgPersonSummary.fromJson', () {
    test('parses member summary', () {
      final person = OrgPersonSummary.fromJson({
        'id': 'member:ou-1',
        'kind': 'member',
        'record_id': 'ou-1',
        'user_id': 'user-1',
        'display_name': 'Jane Foster',
        'email': 'jane@example.com',
        'role': 'foster',
        'photo_url': '/photos/jane.jpg',
        'is_pending': false,
        'active_foster_count': 2,
        'category_rank': 3,
      });

      expect(person.id, 'member:ou-1');
      expect(person.kind, OrgPersonKind.member);
      expect(person.recordId, 'ou-1');
      expect(person.userId, 'user-1');
      expect(person.displayName, 'Jane Foster');
      expect(person.role, OrgMemberRole.foster);
      expect(person.isPending, isFalse);
      expect(person.activeFosterCount, 2);
      expect(person.categoryRank, 3);
      expect(person.isMember, isTrue);
      expect(person.isActiveFoster, isTrue);
      expect(person.detailPath('org-1'), '/o/orgs/org-1/people/member/ou-1');
    });

    test('parses external foster summary', () {
      final person = OrgPersonSummary.fromJson({
        'id': 'external:fp-1',
        'kind': 'external',
        'record_id': 'fp-1',
        'display_name': 'Off-app Parent',
        'email': 'off@example.com',
        'active_foster_count': 0,
      });

      expect(person.kind, OrgPersonKind.external);
      expect(person.isExternal, isTrue);
      expect(person.isActiveFoster, isFalse);
      expect(person.detailPath('org-9'), '/o/orgs/org-9/people/external/fp-1');
    });
  });

  group('OrgPersonSummary.initials', () {
    test('returns initials from display name', () {
      const person = OrgPersonSummary(
        id: 'external:fp-1',
        kind: OrgPersonKind.external,
        recordId: 'fp-1',
        displayName: 'Alice Brown',
      );
      expect(person.initials, 'AB');
    });
  });

  group('OrgPersonDetail.fromJson', () {
    test('parses contact fields and placements', () {
      final detail = OrgPersonDetail.fromJson({
        'id': 'external:fp-1',
        'kind': 'external',
        'record_id': 'fp-1',
        'display_name': 'Off-app Parent',
        'email': 'off@example.com',
        'foster_phone': '555-0000',
        'foster_address': '1 Main St',
        'admin_notes': 'Prefers cats',
        'current_placements': [
          {
            'id': 'pl-1',
            'organization_id': 'org-1',
            'pet_id': 'pet-1',
            'foster_user_id': '',
            'status': 'in_progress',
            'pet_name': 'Whiskers',
          },
        ],
        'past_placements': [
          {
            'id': 'pl-0',
            'organization_id': 'org-1',
            'pet_id': 'pet-0',
            'foster_user_id': '',
            'status': 'adopted',
            'pet_name': 'Buddy',
            'outcome': 'adopted',
          },
        ],
      });

      expect(detail.fosterPhone, '555-0000');
      expect(detail.fosterAddress, '1 Main St');
      expect(detail.adminNotes, 'Prefers cats');
      expect(detail.currentPlacements, hasLength(1));
      expect(detail.currentPlacements.first.petName, 'Whiskers');
      expect(detail.pastPlacements, hasLength(1));
      expect(detail.pastPlacements.first.placement.petName, 'Buddy');
      expect(detail.pastPlacements.first.outcome, 'adopted');
    });
  });

  group('OrgPersonKind wire format', () {
    test('round-trips external kind', () {
      expect(OrgPersonKind.fromWire('external'), OrgPersonKind.external);
      expect(OrgPersonKind.external.wire, 'external');
    });
  });
}
