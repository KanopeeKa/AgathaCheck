import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/features/auth/presentation/widgets/landing/landing_path_card.dart';

void main() {
  testWidgets('landing path card uses accent fill without border', (
    tester,
  ) async {
    const accent = AppColorTokens.petCarePrimary;
    const onAccent = AppColorTokens.inverse;
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LandingPathCard(
            key: const Key('test_path_card'),
            summary: 'For pet parents',
            actionLabel: 'Learn more',
            accentColor: accent,
            onAccentColor: onAccent,
            icon: Icons.pets,
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byKey(const Key('test_path_card')),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, accent);
    expect(material.elevation, 0);

    await tester.tap(find.byKey(const Key('test_path_card')));
    await tester.pumpAndSettle();
    expect(pressed, isTrue);
  });

  testWidgets('landing path card shows forward arrow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LandingPathCard(
            summary: 'For pet parents',
            actionLabel: 'Learn more',
            accentColor: AppColorTokens.petCarePrimary,
            onAccentColor: AppColorTokens.inverse,
            icon: Icons.pets,
            onPressed: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
  });
}
