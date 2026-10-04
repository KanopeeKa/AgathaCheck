import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/auth/presentation/screens/landing_screen.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

void main() {
  testWidgets('LandingScreen shows account deletion message from query param', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/landing?accountDeleted=1',
      routes: [
        GoRoute(
          path: '/landing',
          builder: (context, state) => const LandingScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(LandingScreen));
    final l10n = AppLocalizations.of(context)!;
    expect(find.text(l10n.accountDeletionLandingMessage), findsOneWidget);
  });
}
