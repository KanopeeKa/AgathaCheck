import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/app_notification.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/notification_scope.dart';
import 'package:pet_profile_app/features/notifications/domain/services/notification_scope_rules.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';

AppNotification _notif({String? petId, String? organizationId}) {
  return AppNotification(
    id: 'n1',
    userId: 'u1',
    petId: petId,
    organizationId: organizationId,
    title: 'Test',
    message: 'Test message',
    type: NotificationType.dueSoon,
    isRead: false,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  const owned = Pet(id: 'p-owned', name: 'Bella', species: 'Dog');
  const foster = Pet(
    id: 'p-foster',
    name: 'Rex',
    species: 'Dog',
    isFoster: true,
    organizationId: 'org-1',
    organizationName: 'Shelter',
  );
  const inventory = Pet(
    id: 'p-inv',
    name: 'Spot',
    species: 'Dog',
    organizationId: 'org-1',
    organizationName: 'Shelter',
  );
  const shared = Pet(
    id: 'p-shared',
    name: 'Max',
    species: 'Cat',
    isShared: true,
    guardianName: 'Alice',
  );

  final pets = [owned, foster, inventory, shared];

  group('NotificationScopeRules', () {
    test('owned pet notification is guardian-only', () {
      final n = _notif(petId: 'p-owned');
      expect(
        NotificationScopeRules.includes(n, NotificationScope.guardian, pets),
        isTrue,
      );
      expect(
        NotificationScopeRules.includes(
          n,
          NotificationScope.organization,
          pets,
        ),
        isFalse,
      );
    });

    test('foster pet notification appears in both scopes', () {
      final n = _notif(petId: 'p-foster');
      expect(
        NotificationScopeRules.includes(n, NotificationScope.guardian, pets),
        isTrue,
      );
      expect(
        NotificationScopeRules.includes(
          n,
          NotificationScope.organization,
          pets,
        ),
        isTrue,
      );
    });

    test('org inventory pet notification is org-only', () {
      final n = _notif(petId: 'p-inv');
      expect(
        NotificationScopeRules.includes(n, NotificationScope.guardian, pets),
        isFalse,
      );
      expect(
        NotificationScopeRules.includes(
          n,
          NotificationScope.organization,
          pets,
        ),
        isTrue,
      );
    });

    test('empty organizationId is not treated as org inventory', () {
      const emptyOrgIdPet = Pet(
        id: 'p-empty-org',
        name: 'Empty',
        species: 'Dog',
        organizationId: '',
        organizationName: 'Shelter',
      );
      final n = _notif(petId: 'p-empty-org');
      expect(
        NotificationScopeRules.includes(
          n,
          NotificationScope.organization,
          [emptyOrgIdPet],
        ),
        isFalse,
      );
      expect(
        NotificationScopeRules.includes(
          n,
          NotificationScope.guardian,
          [emptyOrgIdPet],
        ),
        isTrue,
      );
    });

    test('shared pet notification is guardian-only', () {
      final n = _notif(petId: 'p-shared');
      expect(
        NotificationScopeRules.includes(n, NotificationScope.guardian, pets),
        isTrue,
      );
      expect(
        NotificationScopeRules.includes(
          n,
          NotificationScope.organization,
          pets,
        ),
        isFalse,
      );
    });

    test('org-only notification without pet is org-only', () {
      final n = _notif(organizationId: 'org-1');
      expect(
        NotificationScopeRules.includes(
          n,
          NotificationScope.organization,
          pets,
        ),
        isTrue,
      );
      expect(
        NotificationScopeRules.includes(n, NotificationScope.guardian, pets),
        isFalse,
      );
    });

    test('unreadCount respects scope and mute list', () {
      final notifications = [
        _notif(petId: 'p-owned'),
        _notif(petId: 'p-foster'),
        _notif(petId: 'p-inv'),
      ];
      expect(
        NotificationScopeRules.unreadCount(
          notifications,
          NotificationScope.organization,
          pets,
        ),
        2,
      );
      expect(
        NotificationScopeRules.unreadCount(
          notifications,
          NotificationScope.guardian,
          pets,
          mutedPetIds: {'p-foster'},
        ),
        1,
      );
    });
  });
}
