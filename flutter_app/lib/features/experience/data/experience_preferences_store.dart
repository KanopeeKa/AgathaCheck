import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/app_experience.dart';

/// Persists default experience and remember-choice flag (device-local).
class ExperiencePreferencesStore {
  ExperiencePreferencesStore(this._prefs);

  static const defaultExperienceKey = 'experience_default';
  static const rememberChoiceKey = 'experience_remember_choice';

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

  Future<void> clear() async {
    await _prefs.remove(defaultExperienceKey);
    await _prefs.remove(rememberChoiceKey);
  }
}
