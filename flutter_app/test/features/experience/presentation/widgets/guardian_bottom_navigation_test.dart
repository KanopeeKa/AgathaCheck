import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_bottom_navigation.dart';

void main() {
  group('GuardianBottomNavigation', () {
    test('maps each primary destination to its selected tab', () {
      expect(GuardianBottomNavigation.indexFor('/g/home'), 0);
      expect(GuardianBottomNavigation.indexFor('/g/pets'), 1);
      expect(GuardianBottomNavigation.indexFor('/g/events'), 2);
      expect(GuardianBottomNavigation.indexFor('/g/fostering'), 3);
      expect(GuardianBottomNavigation.indexFor('/account'), 4);
    });

    test('is only available on the five Guardian primary destinations', () {
      expect(GuardianBottomNavigation.supports('/g/home'), isTrue);
      expect(GuardianBottomNavigation.supports('/g/pets'), isTrue);
      expect(GuardianBottomNavigation.supports('/g/events'), isTrue);
      expect(GuardianBottomNavigation.supports('/g/fostering'), isTrue);
      expect(GuardianBottomNavigation.supports('/account'), isTrue);
      expect(GuardianBottomNavigation.supports('/g/vets/vet-1'), isFalse);
      expect(GuardianBottomNavigation.supports('/o/orgs'), isFalse);
    });

    test('only uses the mobile bar below the compact breakpoint', () {
      expect(GuardianBottomNavigation.isCompact(599), isTrue);
      expect(GuardianBottomNavigation.isCompact(600), isFalse);
      expect(GuardianBottomNavigation.isCompact(1280), isFalse);
    });
  });
}
