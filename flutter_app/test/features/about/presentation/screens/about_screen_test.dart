import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/about/presentation/screens/about_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('AboutScreen renders app title and legal links', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AboutScreen(),
        ),
        GoRoute(
          path: '/legal/terms',
          builder: (context, state) => const Scaffold(body: Text('Terms')),
        ),
        GoRoute(
          path: '/legal',
          builder: (context, state) => const Scaffold(body: Text('Legal hub')),
        ),
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
    expect(find.text(l10n.termsOfService), findsOneWidget);
    expect(find.text(l10n.viewAllLegalDocuments), findsOneWidget);
  });
}
