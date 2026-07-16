import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the signed-in user completed guardian onboarding on this device.
class GuardianOnboardingStore {
  GuardianOnboardingStore(this._prefs);

  static const completedKey = 'guardian_onboarding_completed';

  final SharedPreferences _prefs;

  bool readCompleted() => _prefs.getBool(completedKey) ?? false;

  Future<void> markCompleted() async {
    await _prefs.setBool(completedKey, true);
  }

  Future<void> clear() async {
    await _prefs.remove(completedKey);
  }
}
