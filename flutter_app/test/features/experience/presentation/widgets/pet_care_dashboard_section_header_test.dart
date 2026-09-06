import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/pet_care_dashboard_section_header.dart';

void main() {
  group('PetCareDashboardSectionChrome', () {
    testWidgets('places title and link on one row when wide enough', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              child: PetCareDashboardSectionChrome(
                title: 'CARE',
                linkLabel: 'All care',
                onLinkPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('CARE'), findsOneWidget);
      expect(find.text('All care'), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('omits link when no destination', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PetCareDashboardSectionChrome(title: 'CARE')),
        ),
      );

      expect(find.text('CARE'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });
  });

  group('petCareDashboardPetCardWidth', () {
    test('keeps mobile cards compact', () {
      expect(petCareDashboardPetCardWidth(320), 142);
      expect(petCareDashboardPetCardWidth(599), 142);
    });

    test('moderately widens cards on tablet and desktop', () {
      expect(petCareDashboardPetCardWidth(600), 160);
      expect(petCareDashboardPetCardWidth(900), 170);
    });

    test('caps card width on very wide screens', () {
      expect(petCareDashboardPetCardWidth(1200), 172);
      expect(petCareDashboardPetCardWidth(2000), 172);
    });
  });

  group('petCareDashboardAddPetTileWidth', () {
    test('scales add tile modestly without matching pet cards', () {
      expect(petCareDashboardAddPetTileWidth(320), 72);
      expect(petCareDashboardAddPetTileWidth(900), 80);
      expect(
        petCareDashboardAddPetTileWidth(1280),
        lessThan(petCareDashboardPetCardWidth(1280)),
      );
    });
  });
}
