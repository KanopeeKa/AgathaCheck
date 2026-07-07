import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:pet_profile_app/features/subscription/presentation/screens/paywall_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

void main() {
  testWidgets('PaywallScreen renders subscription title for free tier', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(FakePrefs()),
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          revenueCatServiceProvider.overrideWithValue(FakeRevenueCatService()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PaywallScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(PaywallScreen));
    final l = AppLocalizations.of(context)!;

    expect(find.text(l.subscriptionTitle), findsOneWidget);
  });
}
