import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/care_family_custom_glyph.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/care_family_icon.dart';

void main() {
  group('CareFamilyIcon', () {
    for (final family in CareFamily.values) {
      testWidgets('renders icon for $family', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CareFamilyIcon(key: Key('icon_$family'), family: family),
            ),
          ),
        );

        expect(find.byKey(Key('icon_$family')), findsOneWidget);
      });
    }

    testWidgets('chip uses surfaceAlt background and plum ink', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CareFamilyIcon(family: CareFamily.medication)),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(CareFamilyIcon),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColorTokens.surfaceAlt);

      final icon = tester.widget<Icon>(find.byIcon(Icons.medication_outlined));
      expect(icon.color, AppColorTokens.petCarePrimary);
    });

    testWidgets('nail care uses scissors icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CareFamilyIcon(family: CareFamily.nailCare)),
        ),
      );

      expect(find.byIcon(Icons.content_cut_outlined), findsOneWidget);
    });

    testWidgets('wellness and dental use custom glyphs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CareFamilyIcon(family: CareFamily.wellnessReview),
                CareFamilyIcon(family: CareFamily.dental),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CareFamilyCustomGlyph), findsNWidgets(2));
    });

    testWidgets('forEntry infers family from health entry type', (
      tester,
    ) async {
      final entry = HealthEntry(
        id: 'e1',
        petId: 'p1',
        name: 'Bravecto',
        type: HealthEntryType.preventive,
        frequency: HealthFrequency.monthly,
        startDate: DateTime(2024, 1, 1),
        careFamily: CareFamily.parasitePrevention,
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CareFamilyIcon.forEntry(entry))),
      );

      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });
  });
}
