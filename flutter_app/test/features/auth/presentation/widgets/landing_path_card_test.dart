import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/features/auth/presentation/widgets/landing/landing_path_card.dart';

void main() {
  testWidgets('landing path card uses accent fill without border', (tester) async {
    const accent = AppColorTokens.guardianPrimary;
    const onAccent = AppColorTokens.inverse;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LandingPathCard(
            key: const Key('test_path_card'),
            summary: 'For pet parents',
            expandLabel: 'See how it works',
            collapseLabel: 'Show less',
            detail: 'Coordinate with your household.',
            accentColor: accent,
            onAccentColor: onAccent,
            icon: Icons.pets,
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

    final decorationFinder = find.descendant(
      of: find.byKey(const Key('test_path_card')),
      matching: find.byType(DecoratedBox),
    );
    expect(decorationFinder, findsNothing);
  });

  testWidgets('landing path card expands on tap', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LandingPathCard(
            summary: 'For pet parents',
            expandLabel: 'See how it works',
            collapseLabel: 'Show less',
            detail: 'Coordinate with your household.',
            accentColor: AppColorTokens.guardianPrimary,
            onAccentColor: AppColorTokens.inverse,
            icon: Icons.pets,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Coordinate with your household'), findsNothing);

    await tester.tap(find.text('See how it works'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Coordinate with your household'), findsOneWidget);
    expect(find.text('Show less'), findsOneWidget);
  });
}
