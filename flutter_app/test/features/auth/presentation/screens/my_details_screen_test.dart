import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pet_profile_app/features/auth/presentation/screens/my_details_screen.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

void main() {
  testWidgets('MyDetailsScreen renders and shows not logged in if user is null', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith((ref) {
            final notifier = AuthNotifier(FakeAuthService(), prefs);
            notifier.state = const AuthState();
            return notifier;
          }),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MyDetailsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scaffoldContext = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(scaffoldContext)!;
    expect(find.text(l10n.notLoggedIn), findsOneWidget);
  });
}
