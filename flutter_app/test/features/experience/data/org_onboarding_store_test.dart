import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/data/org_onboarding_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OrgOnboardingStore', () {
    test('defaults to not completed', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = OrgOnboardingStore(prefs);
      expect(store.readCompleted(), isFalse);
    });

    test('markCompleted persists flag', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = OrgOnboardingStore(prefs);
      await store.markCompleted();
      expect(store.readCompleted(), isTrue);
    });

    test('clear removes flag', () async {
      SharedPreferences.setMockInitialValues({
        OrgOnboardingStore.completedKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final store = OrgOnboardingStore(prefs);
      await store.clear();
      expect(store.readCompleted(), isFalse);
    });
  });
}
