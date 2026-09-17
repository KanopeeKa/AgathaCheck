import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/pet_care_dashboard_ambient_deco.dart';

void main() {
  group('petCarePetRailDecoModeForLeftover', () {
    test('returns null when slack is too small', () {
      expect(petCarePetRailDecoModeForLeftover(80), isNull);
      expect(petCarePetRailDecoModeForLeftover(119), isNull);
    });

    test('returns catOnly for modest slack', () {
      expect(
        petCarePetRailDecoModeForLeftover(150),
        PetCarePetRailDecoMode.catOnly,
      );
    });

    test('returns catAndBall for medium slack', () {
      expect(
        petCarePetRailDecoModeForLeftover(220),
        PetCarePetRailDecoMode.catAndBall,
      );
    });

    test('returns full for generous slack', () {
      expect(
        petCarePetRailDecoModeForLeftover(320),
        PetCarePetRailDecoMode.full,
      );
    });
  });

  group('petCarePetRailContentWidth', () {
    test('sums cards, separators, and add tile', () {
      expect(
        petCarePetRailContentWidth(
          petCount: 4,
          cardWidth: 172,
          addTileWidth: 80,
        ),
        816,
      );
    });
  });

  group('PetCarePetRailYarnDeco', () {
    testWidgets('renders without semantics and ignores pointers', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 96,
              child: PetCarePetRailYarnDeco(
                mode: PetCarePetRailDecoMode.full,
                width: 300,
                height: 96,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('pet_care_dashboard_pet_rail_deco')),
        findsOneWidget,
      );
      expect(find.byType(ExcludeSemantics), findsWidgets);
      expect(find.byType(IgnorePointer), findsWidgets);
    });
  });

  group('PetCareDashboardDecoThresholds', () {
    test('ambient sketches use 80% opacity', () {
      expect(PetCareDashboardDecoThresholds.opacity, 0.8);
    });
  });

}
