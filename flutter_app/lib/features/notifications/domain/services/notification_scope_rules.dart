import '../../../pet_profile/domain/entities/pet.dart';
import '../entities/app_notification.dart';
import '../entities/notification_scope.dart';

/// Pure rules for splitting notifications between pet care and org experiences.
class NotificationScopeRules {
  const NotificationScopeRules._();

  /// Org inventory (shelter-owned, not foster/shared).
  static bool isOrgInventoryPet(Pet pet) {
    return !pet.passedAway &&
        !pet.isFoster &&
        !pet.isShared &&
        pet.organizationId != null &&
        pet.organizationId!.isNotEmpty &&
        pet.organizationName != null &&
        pet.organizationName!.isNotEmpty;
  }

  /// Personally owned pet (not foster, shared, or org inventory).
  static bool isPersonallyOwnedPet(Pet pet) {
    return !pet.passedAway &&
        !pet.isFoster &&
        !pet.isShared &&
        !isOrgInventoryPet(pet);
  }

  static Pet? _petForNotification(
    AppNotification notification,
    List<Pet> pets,
  ) {
    final petId = notification.petId;
    if (petId == null || petId.isEmpty) return null;
    for (final pet in pets) {
      if (pet.id == petId) return pet;
    }
    return null;
  }

  static bool _includesPet(Pet pet, NotificationScope scope) {
    switch (scope) {
      case NotificationScope.petCare:
        return isPersonallyOwnedPet(pet) || pet.isFoster || pet.isShared;
      case NotificationScope.organization:
        return pet.isFoster || isOrgInventoryPet(pet);
    }
  }

  /// Whether [notification] should appear in [scope] given the user's [pets].
  static bool includes(
    AppNotification notification,
    NotificationScope scope,
    List<Pet> pets,
  ) {
    final pet = _petForNotification(notification, pets);
    if (pet != null) {
      return _includesPet(pet, scope);
    }

    final hasOrg =
        notification.organizationId != null &&
        notification.organizationId!.isNotEmpty;

    if (hasOrg) {
      return scope == NotificationScope.organization;
    }

    return scope == NotificationScope.petCare;
  }

  static List<AppNotification> filter(
    Iterable<AppNotification> notifications,
    NotificationScope scope,
    List<Pet> pets, {
    Set<String> mutedPetIds = const {},
  }) {
    return notifications
        .where(
          (n) =>
              n.petId == null ||
              n.petId!.isEmpty ||
              !mutedPetIds.contains(n.petId),
        )
        .where((n) => includes(n, scope, pets))
        .toList();
  }

  static int unreadCount(
    Iterable<AppNotification> notifications,
    NotificationScope scope,
    List<Pet> pets, {
    Set<String> mutedPetIds = const {},
  }) {
    return filter(
      notifications,
      scope,
      pets,
      mutedPetIds: mutedPetIds,
    ).where((n) => !n.isRead).length;
  }
}
