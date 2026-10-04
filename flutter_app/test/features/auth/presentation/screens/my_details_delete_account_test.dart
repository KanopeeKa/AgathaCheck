import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/features/auth/data/auth_service.dart';
import 'package:pet_profile_app/features/auth/data/token_store.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/auth/presentation/screens/landing_screen.dart';
import 'package:pet_profile_app/features/auth/presentation/screens/my_details_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/fakes.dart';

void main() {
  Future<void> pumpDeleteFlow({
    required WidgetTester tester,
    required int deleteStatusCode,
    required String deleteBodyJson,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final client = MockClient((request) async {
      if (request.method == 'DELETE' && request.url.path.endsWith('/auth/me')) {
        return http.Response(deleteBodyJson, deleteStatusCode);
      }
      if (request.url.path.endsWith('/auth/logout')) {
        return http.Response('{}', 200);
      }
      return http.Response('{}', 404);
    });

    final authService = AuthService(baseUrl: 'http://test', client: client);

    final router = GoRouter(
      initialLocation: '/my-details',
      routes: [
        GoRoute(
          path: '/my-details',
          builder: (context, state) => const MyDetailsScreen(),
        ),
        GoRoute(
          path: '/landing',
          builder: (context, state) => const LandingScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          apiBaseUrlProvider.overrideWith((ref) => 'http://test'),
          authServiceProvider.overrideWithValue(authService),
          authProvider.overrideWith((ref) {
            final notifier = AuthNotifier(authService, PrefsTokenStore(prefs));
            notifier.state = loggedInAuthState;
            return notifier;
          }),
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
  }

  testWidgets('delete account HTTP 202 logs out and shows landing message', (
    tester,
  ) async {
    await pumpDeleteFlow(
      tester: tester,
      deleteStatusCode: 202,
      deleteBodyJson: json.encode({
        'message': 'accepted',
        'erasure': {
          'operation_id': 'op-1',
          'status': 'accepted',
          'status_token': 'tok',
        },
      }),
    );

    final scaffoldContext = tester.element(find.byType(MyDetailsScreen));
    final l10n = AppLocalizations.of(scaffoldContext)!;

    await tester.scrollUntilVisible(
      find.text(l10n.deleteAccount),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(l10n.deleteAccount));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'E2eTestPass1',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, l10n.deleteAccount),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.text(l10n.accountDeletionLandingMessage), findsOneWidget);
  });

  testWidgets('delete account HTTP 200 logs out and shows landing message', (
    tester,
  ) async {
    await pumpDeleteFlow(
      tester: tester,
      deleteStatusCode: 200,
      deleteBodyJson: json.encode({'message': 'deleted'}),
    );

    final scaffoldContext = tester.element(find.byType(MyDetailsScreen));
    final l10n = AppLocalizations.of(scaffoldContext)!;

    await tester.scrollUntilVisible(
      find.text(l10n.deleteAccount),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(l10n.deleteAccount));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'E2eTestPass1',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, l10n.deleteAccount),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.text(l10n.accountDeletionLandingMessage), findsOneWidget);
  });
}
