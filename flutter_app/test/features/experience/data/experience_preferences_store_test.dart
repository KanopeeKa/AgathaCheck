import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/data/experience_preferences_store.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExperiencePreferencesStore', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('persists default experience when remember is set', () async {
      final store = ExperiencePreferencesStore(prefs);
      await store.writeDefaultExperience(AppExperience.guardian);
      expect(store.readDefaultExperience(), AppExperience.guardian);
      expect(store.readRememberChoice(), isTrue);
    });

    test('clear removes saved default', () async {
      final store = ExperiencePreferencesStore(prefs);
      await store.writeDefaultExperience(AppExperience.organization);
      await store.clear();
      expect(store.readDefaultExperience(), isNull);
      expect(store.readRememberChoice(), isFalse);
    });
  });
}
