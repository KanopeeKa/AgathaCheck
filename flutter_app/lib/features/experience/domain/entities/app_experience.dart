/// Product experience shell: individual guardian vs shelter/organisation.
enum AppExperience { guardian, organization }

extension AppExperienceWire on AppExperience {
  String get wire => switch (this) {
    AppExperience.guardian => 'guardian',
    AppExperience.organization => 'organization',
  };

  static AppExperience? fromWire(String? value) => switch (value) {
    'guardian' => AppExperience.guardian,
    'organization' => AppExperience.organization,
    _ => null,
  };

  String homePath({String? orgId}) => switch (this) {
    AppExperience.guardian => '/g/home',
    AppExperience.organization =>
      orgId != null && orgId.isNotEmpty ? '/o/$orgId' : '/o/home',
  };

  String get eventsPath => switch (this) {
    AppExperience.guardian => '/g/events',
    AppExperience.organization => '/o/events',
  };

  String get settingsPath => switch (this) {
    AppExperience.guardian => '/g/settings',
    AppExperience.organization => '/o/settings',
  };
}
