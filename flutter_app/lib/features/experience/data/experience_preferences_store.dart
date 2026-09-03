import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/app_experience.dart';

/// Persists experience section preferences (device-local).
class ExperiencePreferencesStore {
  ExperiencePreferencesStore(this._prefs);

  static const defaultExperienceKey = 'experience_default';
  static const rememberChoiceKey = 'experience_remember_choice';
  static const lastAppSectionKey = 'last_app_section';

  final SharedPreferences _prefs;

  AppExperience? readDefaultExperience() =>
      AppExperienceWire.fromWire(_prefs.getString(defaultExperienceKey));

  Future<void> writeDefaultExperience(AppExperience? experience) async {
    if (experience == null) {
      await _prefs.remove(defaultExperienceKey);
      await _prefs.remove(rememberChoiceKey);
      return;
    }
    await _prefs.setString(defaultExperienceKey, experience.wire);
    await _prefs.setBool(rememberChoiceKey, true);
  }

  bool readRememberChoice() => _prefs.getBool(rememberChoiceKey) ?? false;

  AppExperience? readLastAppSection() =>
      AppExperienceWire.fromWire(_prefs.getString(lastAppSectionKey));

  Future<void> writeLastAppSection(AppExperience section) async {
    await _prefs.setString(lastAppSectionKey, section.wire);
  }

  Future<void> clear() async {
    await _prefs.remove(defaultExperienceKey);
    await _prefs.remove(rememberChoiceKey);
  }
}
