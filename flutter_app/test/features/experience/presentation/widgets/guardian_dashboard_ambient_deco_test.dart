import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_dashboard_ambient_deco.dart';

void main() {
  group('guardianPetRailDecoModeForLeftover', () {
    test('returns null when slack is too small', () {
      expect(guardianPetRailDecoModeForLeftover(80), isNull);
      expect(guardianPetRailDecoModeForLeftover(119), isNull);
    });

    test('returns catOnly for modest slack', () {
      expect(
        guardianPetRailDecoModeForLeftover(150),
        GuardianPetRailDecoMode.catOnly,
      );
    });

    test('returns catAndBall for medium slack', () {
      expect(
        guardianPetRailDecoModeForLeftover(220),
        GuardianPetRailDecoMode.catAndBall,
      );
    });

    test('returns full for generous slack', () {
      expect(
        guardianPetRailDecoModeForLeftover(320),
        GuardianPetRailDecoMode.full,
      );
    });
  });

  group('guardianPetRailContentWidth', () {
    test('sums cards, separators, and add tile', () {
      expect(
        guardianPetRailContentWidth(
          petCount: 4,
          cardWidth: 172,
          addTileWidth: 80,
        ),
        816,
      );
    });
  });

  group('GuardianPetRailYarnDeco', () {
    testWidgets('renders without semantics and ignores pointers', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 96,
              child: GuardianPetRailYarnDeco(
                mode: GuardianPetRailDecoMode.full,
                width: 300,
                height: 96,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('guardian_dashboard_pet_rail_deco')),
        findsOneWidget,
      );
      expect(find.byType(ExcludeSemantics), findsWidgets);
      expect(find.byType(IgnorePointer), findsWidgets);
    });
  });

  group('GuardianDashboardDecoThresholds', () {
    test('ambient sketches use 80% opacity', () {
      expect(GuardianDashboardDecoThresholds.opacity, 0.8);
    });
  });

  group('guardianCareTeamPuppyDecoAllowed', () {
    test('requires wide desk layout and care team cards', () {
      expect(
        guardianCareTeamPuppyDecoAllowed(
          useWideDeskLayout: true,
          hasCareTeamCards: true,
        ),
        isTrue,
      );
      expect(
        guardianCareTeamPuppyDecoAllowed(
          useWideDeskLayout: false,
          hasCareTeamCards: true,
        ),
        isFalse,
      );
      expect(
        guardianCareTeamPuppyDecoAllowed(
          useWideDeskLayout: true,
          hasCareTeamCards: false,
        ),
        isFalse,
      );
    });
  });

  group('GuardianCareTeamPuppyDeco', () {
    testWidgets('renders puppy asset', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: GuardianCareTeamPuppyDeco())),
      );

      expect(
        find.byKey(const Key('guardian_dashboard_care_team_puppy_deco')),
        findsOneWidget,
      );
    });
  });
}
