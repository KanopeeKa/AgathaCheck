import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the signed-in user completed Pet Care onboarding on this device.
class PetCareOnboardingStore {
  PetCareOnboardingStore(this._prefs);

  static const completedKey = 'pet_care_onboarding_completed';
  static const legacyCompletedKey = 'guardian_onboarding_completed';

  final SharedPreferences _prefs;

  bool readCompleted() {
    if (_prefs.getBool(completedKey) == true) return true;
    return _prefs.getBool(legacyCompletedKey) ?? false;
  }

  Future<void> markCompleted() async {
    await _prefs.setBool(completedKey, true);
    await _prefs.remove(legacyCompletedKey);
  }

  Future<void> clear() async {
    await _prefs.remove(completedKey);
    await _prefs.remove(legacyCompletedKey);
  }
}
