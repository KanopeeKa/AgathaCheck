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
      await store.writeDefaultExperience(AppExperience.petCare);
      expect(store.readDefaultExperience(), AppExperience.petCare);
      expect(store.readRememberChoice(), isTrue);
    });

    test('clear removes saved default', () async {
      final store = ExperiencePreferencesStore(prefs);
      await store.writeDefaultExperience(AppExperience.organization);
      await store.clear();
      expect(store.readDefaultExperience(), isNull);
      expect(store.readRememberChoice(), isFalse);
    });

    test('show organisation section defaults false', () {
      final store = ExperiencePreferencesStore(prefs);
      expect(store.readShowOrganisationSection(), isFalse);
    });

    test('persists show organisation section', () async {
      final store = ExperiencePreferencesStore(prefs);
      await store.writeShowOrganisationSection(true);
      expect(store.readShowOrganisationSection(), isTrue);
    });

    test('last app section defaults null', () {
      final store = ExperiencePreferencesStore(prefs);
      expect(store.readLastAppSection(), isNull);
    });

    test('persists last app section wire values', () async {
      final store = ExperiencePreferencesStore(prefs);
      await store.writeLastAppSection(AppExperience.organization);
      expect(store.readLastAppSection(), AppExperience.organization);
      await store.writeLastAppSection(AppExperience.petCare);
      expect(store.readLastAppSection(), AppExperience.petCare);
      expect(store.readDefaultExperience(), isNull);
    });

    test('dual-reads legacy guardian wire for last app section', () async {
      final store = ExperiencePreferencesStore(prefs);
      await prefs.setString(
        ExperiencePreferencesStore.lastAppSectionKey,
        'guardian',
      );
      expect(store.readLastAppSection(), AppExperience.petCare);
    });
  });
}
