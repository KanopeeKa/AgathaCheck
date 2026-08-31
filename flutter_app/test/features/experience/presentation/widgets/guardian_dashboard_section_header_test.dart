import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_dashboard_section_header.dart';

void main() {
  group('guardianDashboardPetCardWidth', () {
    test('keeps mobile cards compact', () {
      expect(guardianDashboardPetCardWidth(320), 142);
      expect(guardianDashboardPetCardWidth(599), 142);
    });

    test('moderately widens cards on tablet and desktop', () {
      expect(guardianDashboardPetCardWidth(600), 160);
      expect(guardianDashboardPetCardWidth(900), 170);
    });

    test('caps card width on very wide screens', () {
      expect(guardianDashboardPetCardWidth(1200), 172);
      expect(guardianDashboardPetCardWidth(2000), 172);
    });
  });

  group('guardianDashboardAddPetTileWidth', () {
    test('scales add tile modestly without matching pet cards', () {
      expect(guardianDashboardAddPetTileWidth(320), 72);
      expect(guardianDashboardAddPetTileWidth(900), 80);
      expect(
        guardianDashboardAddPetTileWidth(1280),
        lessThan(guardianDashboardPetCardWidth(1280)),
      );
    });
  });
}
