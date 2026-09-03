/// Product experience shell: individual pet care vs shelter/organisation.
enum AppExperience {
  petCare,
  organization;

  /// Deprecated compile-time alias — use [petCare].
  @Deprecated('Use AppExperience.petCare')
  static const guardian = petCare;
}

extension AppExperienceWire on AppExperience {
  String get wire => switch (this) {
    AppExperience.petCare => 'pet_care',
    AppExperience.organization => 'organization',
  };

  static AppExperience? fromWire(String? value) => switch (value) {
    'pet_care' || 'guardian' => AppExperience.petCare,
    'organization' => AppExperience.organization,
    _ => null,
  };

  String homePath({String? orgId}) => switch (this) {
    AppExperience.petCare => '/pc/home',
    AppExperience.organization =>
      orgId != null && orgId.isNotEmpty ? '/o/$orgId' : '/o/orgs',
  };

  String get eventsPath => switch (this) {
    AppExperience.petCare => '/pc/events',
    AppExperience.organization => '/o/events',
  };

  String get settingsPath => switch (this) {
    AppExperience.petCare => '/pc/settings',
    AppExperience.organization => '/o/settings',
  };
}
