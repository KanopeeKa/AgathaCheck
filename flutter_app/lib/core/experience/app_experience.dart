/// Active product experience — Pet Care only (`/pc/*`).
///
/// [AppExperience.organization] is retained for wire compatibility and legacy
/// references; it must not be offered in UI.
enum AppExperience {
  petCare,
  @Deprecated('Frozen shelter workspace — not active in the product')
  organization,
}

extension AppExperienceWire on AppExperience {
  String get wire => switch (this) {
    AppExperience.petCare => 'pet_care',
    AppExperience.organization => 'organization',
  };

  static AppExperience? fromWire(String? value) => switch (value) {
    'pet_care' || 'guardian' => AppExperience.petCare,
    'organization' => AppExperience.petCare,
    _ => null,
  };

  String homePath({String? orgId}) => '/pc/home';

  String get eventsPath => '/pc/events';

  String get settingsPath => '/pc/settings';
}
