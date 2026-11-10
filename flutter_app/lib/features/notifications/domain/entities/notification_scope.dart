/// Which experience shell a notification list or badge belongs to.
enum NotificationScope {
  /// Personal pets, shared pets, and general Pet Care items.
  petCare,

  @Deprecated('Frozen organisation shell')
  organization;

  /// Deprecated compile-time alias — use [petCare].
  @Deprecated('Use NotificationScope.petCare')
  static const guardian = petCare;
}

extension NotificationScopeWire on NotificationScope {
  String get wire => switch (this) {
    NotificationScope.petCare => 'pet_care',
    NotificationScope.organization => 'pet_care',
  };

  static NotificationScope? fromWire(String? value) => switch (value) {
    'pet_care' || 'guardian' || 'organization' => NotificationScope.petCare,
    _ => null,
  };
}
