import 'package:shared_preferences/shared_preferences.dart';

import '../domain/profile_completeness_kind.dart';

/// Local dismiss timestamps for profile completeness nag budget (PR-05).
class ProfileCompletenessDismissalStore {
  ProfileCompletenessDismissalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<ProfileCompletenessDismissalStore> create() async {
    return ProfileCompletenessDismissalStore(
      await SharedPreferences.getInstance(),
    );
  }

  static String _key(String petId, ProfileCompletenessKind kind) =>
      'profile_completeness_dismissed_${petId}_${kind.name}';

  Future<void> recordDismiss(String petId, ProfileCompletenessKind kind) async {
    await _prefs.setString(
      _key(petId, kind),
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  DateTime? dismissedAt(String petId, ProfileCompletenessKind kind) {
    final raw = _prefs.getString(_key(petId, kind));
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }
}
