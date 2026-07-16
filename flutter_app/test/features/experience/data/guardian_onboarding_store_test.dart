import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/data/guardian_onboarding_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GuardianOnboardingStore', () {
    test('defaults to not completed', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = GuardianOnboardingStore(prefs);
      expect(store.readCompleted(), isFalse);
    });

    test('markCompleted persists flag', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = GuardianOnboardingStore(prefs);
      await store.markCompleted();
      expect(store.readCompleted(), isTrue);
    });

    test('clear removes flag', () async {
      SharedPreferences.setMockInitialValues({
        GuardianOnboardingStore.completedKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final store = GuardianOnboardingStore(prefs);
      await store.clear();
      expect(store.readCompleted(), isFalse);
    });
  });
}
