import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/about/presentation/screens/about_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('AboutScreen renders app title and version', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const AboutScreen()),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AboutScreen));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text(l10n.aboutUs), findsOneWidget);
    expect(find.text(l10n.appTitle), findsOneWidget);
    expect(find.text(l10n.appTagline), findsOneWidget);
    expect(find.text(l10n.appVersion), findsOneWidget);
    expect(find.text(l10n.termsOfService), findsNothing);
    expect(find.text(l10n.viewAllLegalDocuments), findsNothing);
  });
}
