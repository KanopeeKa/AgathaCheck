import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/features/auth/presentation/widgets/landing/landing_audience_section.dart';

void main() {
  testWidgets('landing audience section shows placeholder and copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LandingAudienceSection(
            title: 'Pet parents',
            body: 'Body copy placeholder',
            placeholderLabel: 'Screenshot coming soon',
            accentColor: AppColorTokens.petCarePrimary,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pet parents'), findsOneWidget);
    expect(find.text('Body copy placeholder'), findsOneWidget);
    expect(find.text('Screenshot coming soon'), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });
}
