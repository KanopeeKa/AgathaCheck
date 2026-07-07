import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/help/presentation/screens/help_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('HelpScreen renders FAQ sections', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HelpScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(HelpScreen));
    final l = AppLocalizations.of(context)!;

    expect(find.text(l.helpSubtitle), findsOneWidget);
    expect(find.text(l.faqAccountTitle), findsOneWidget);
    expect(find.text(l.faqPetProfileTitle), findsOneWidget);

    await tester.scrollUntilVisible(find.text(l.faqSubscriptionTitle), 200);
    expect(find.text(l.faqSubscriptionTitle), findsOneWidget);
  });
}
