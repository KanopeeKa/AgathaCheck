/// Which experience shell a notification list or badge belongs to.
enum NotificationScope {
  /// Personal pets, shared pets, foster pets, and non-org general items.
  petCare,

  /// Org inventory pets, foster pets, and organisation-only items.
  organization;

  /// Deprecated compile-time alias — use [petCare].
  @Deprecated('Use NotificationScope.petCare')
  static const guardian = petCare;
}

extension NotificationScopeWire on NotificationScope {
  String get wire => switch (this) {
    NotificationScope.petCare => 'pet_care',
    NotificationScope.organization => 'organization',
  };

  static NotificationScope? fromWire(String? value) => switch (value) {
    'pet_care' || 'guardian' => NotificationScope.petCare,
    'organization' => NotificationScope.organization,
    _ => null,
  };
}
