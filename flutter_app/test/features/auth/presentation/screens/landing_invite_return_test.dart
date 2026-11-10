import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/router/invite_return.dart';
import 'package:pet_profile_app/core/web/native_login.dart';
import 'package:pet_profile_app/features/auth/data/token_store.dart';
import 'package:pet_profile_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/auth/presentation/screens/landing_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/pet_care_onboarding_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

class _LoginOnSubmitAuthNotifier extends AuthNotifier {
  _LoginOnSubmitAuthNotifier()
    : super(FakeAuthRepository(), PrefsTokenStore(FakePrefs())) {
    state = const AuthState();
  }

  @override
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = loggedInAuthState;
  }

  @override
  Future<void> signup({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
  }) async {
    state = loggedInAuthState;
  }
}

Future<void> _pumpSettleBounded(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 200));
}

GoRouter _router({String initialLocation = '/landing'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/landing',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/app/resolve',
        builder: (context, state) => const Scaffold(body: Text('resolve')),
      ),
      GoRoute(
        path: '/pc/onboarding',
        builder: (context, state) => const PetCareOnboardingScreen(),
      ),
      GoRoute(
        path: '/invite/:code',
        builder: (context, state) =>
            Scaffold(body: Text('invite:${state.pathParameters['code']}')),
      ),
    ],
  );
}

Widget _app(GoRouter router, AuthNotifier authNotifier) {
  return ProviderScope(
    overrides: [authProvider.overrideWith((ref) => authNotifier)],
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
  );
}

void main() {
  testWidgets('login preserves invite returnTo through resolve', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final auth = _LoginOnSubmitAuthNotifier();
    final router = _router();
    await tester.pumpWidget(_app(router, auth));
    router.go('/landing?returnTo=%2Finvite%2Fabc');
    await _pumpSettleBounded(tester);

    await tester.enterText(find.byKey(const Key('login_email_field')), 'a@b.c');
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'secret12',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await _pumpSettleBounded(tester);

    expect(router.state.uri.toString(), '/app/resolve?returnTo=%2Finvite%2Fabc');
  });

  testWidgets('signup preserves invite returnTo through resolve', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final auth = _LoginOnSubmitAuthNotifier();
    final router = _router();
    await tester.pumpWidget(_app(router, auth));
    router.go('/landing?returnTo=%2Finvite%2Fabc');
    await _pumpSettleBounded(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(LandingScreen)),
    )!;
    await tester.tap(find.text(l10n.createAccount));
    await _pumpSettleBounded(tester);

    await tester.enterText(
      find.byKey(const Key('signup_first_name_field')),
      'Alex',
    );
    await tester.enterText(
      find.byKey(const Key('signup_last_name_field')),
      'Lee',
    );
    await tester.enterText(
      find.byKey(const Key('signup_email_field')),
      'new@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('signup_password_field')),
      'password12',
    );
    await tester.enterText(
      find.byKey(const Key('signup_confirm_password_field')),
      'password12',
    );
    await tester.ensureVisible(find.byKey(const Key('signup_submit_button')));
    await tester.tap(find.byKey(const Key('signup_submit_button')));
    await _pumpSettleBounded(tester);

    expect(router.state.uri.toString(), '/app/resolve?returnTo=%2Finvite%2Fabc');
  });

  testWidgets('native login preserves invite returnTo through resolve', (
    tester,
  ) async {
    final auth = _LoginOnSubmitAuthNotifier();
    final router = _router();
    final nativeLogin = createNativeLogin();

    Future<void> handleNativeLogin(String email, String password) async {
      await auth.login(email: email, password: password);
      if (!auth.state.isLoggedIn) return;
      final context = tester.element(find.byType(LandingScreen));
      final returnTo = inviteReturnToFromState(GoRouterState.of(context));
      router.go(appendInviteReturnQuery('/app/resolve', returnTo));
    }

    await tester.pumpWidget(_app(router, auth));
    router.go('/landing?returnTo=%2Finvite%2Fabc');
    await _pumpSettleBounded(tester);

    nativeLogin.attachInline(
      emailLabel: 'Email',
      passwordLabel: 'Password',
      signInLabel: 'Sign in',
      forgotLabel: 'Forgot',
      emailRequiredLabel: 'Required',
      passwordRequiredLabel: 'Required',
      onSubmit: handleNativeLogin,
      onForgot: () {},
    );

    await handleNativeLogin('native@example.com', 'password12');
    await _pumpSettleBounded(tester);

    expect(router.state.uri.toString(), '/app/resolve?returnTo=%2Finvite%2Fabc');
  });

  testWidgets('onboarding skip returns to stored invite route', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final router = _router(
      initialLocation: '/pc/onboarding?returnTo=%2Finvite%2Fabc',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
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
    await _pumpSettleBounded(tester);

    await tester.tap(find.byKey(const Key('pet_care_onboarding_skip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(router.state.uri.path, '/invite/abc');
  });
}
