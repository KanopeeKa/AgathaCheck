import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_parent.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_self_prefs.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';
import 'package:pet_profile_app/features/organization/domain/services/foster_visibility.dart';

void main() {
  group('foster_visibility service', () {
    test('sortFosterParentsForViewer pins self card first', () {
      final parents = [
        const FosterParent(
          id: '1',
          kind: FosterParentKind.member,
          userId: 'other',
          displayName: 'Amy Zulu',
        ),
        const FosterParent(
          id: '2',
          kind: FosterParentKind.member,
          userId: 'self',
          displayName: 'Self Foster',
          isSelfCard: true,
        ),
      ];

      final sorted = sortFosterParentsForViewer(
        parents: parents,
        viewerUserId: 'self',
      );

      expect(sorted.first.userId, 'self');
    });

    test('canManageFosters uses permission table defaults', () {
      expect(canManageFosters(OrgMemberRole.admin, 'org-1'), isTrue);
      expect(canManageFosters(OrgMemberRole.foster, 'org-1'), isFalse);
    });

    test('formatAddressForViewer respects town-only visibility', () {
      expect(
        formatAddressForViewer(
          '12 Oak Lane, Springfield',
          FosterAddressVisibility.town,
        ),
        'Springfield',
      );
      expect(
        formatAddressForViewer(
          '12 Oak Lane, Springfield',
          FosterAddressVisibility.hidden,
        ),
        '',
      );
    });

    test('FosterSelfPrefs round-trips wire values', () {
      const prefs = FosterSelfPrefs(
        visibleTo: FosterVisibleTo.admins,
        addressVisibility: FosterAddressVisibility.town,
        contactVisibility: FosterContactVisibility.email,
        messageChannel: FosterMessageNotificationChannel.email,
      );
      final json = prefs.toJson();
      final parsed = FosterSelfPrefs.fromJson(json);
      expect(parsed.visibleTo, FosterVisibleTo.admins);
      expect(parsed.addressVisibility, FosterAddressVisibility.town);
      expect(parsed.contactVisibility, FosterContactVisibility.email);
    });
  });
}
