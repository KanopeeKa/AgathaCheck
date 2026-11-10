import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/subscription/domain/entities/subscription_status.dart';
import 'package:pet_profile_app/features/subscription/presentation/widgets/paywall_body_content.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('manage subscription enabled when management URL exists', (
    tester,
  ) async {
    var manageTapped = false;
    const status = SubscriptionStatus(
      tier: SubscriptionTier.unlimited,
      isActive: true,
      managementUrl: 'https://apps.apple.com/account/subscriptions',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l = AppLocalizations.of(context)!;
            return Scaffold(
              body: PaywallBodyContent(
                theme: Theme.of(context),
                subscriptionStatus: status,
                loading: false,
                error: null,
                offerings: const [],
                purchasing: false,
                onPurchasePackage: (_) {},
                onRestorePurchases: () {},
                onReloadOfferings: () {},
                onManageSubscription: () => manageTapped = true,
                formatDate: (d) => d.toIso8601String(),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byKey(const Key('manage_subscription_button'));
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pump();
    expect(manageTapped, isTrue);
  });

  testWidgets('manage subscription disabled with caption when URL missing', (
    tester,
  ) async {
    late AppLocalizations l;
    const status = SubscriptionStatus(
      tier: SubscriptionTier.unlimited,
      isActive: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l = AppLocalizations.of(context)!;
            return Scaffold(
              body: PaywallBodyContent(
                theme: Theme.of(context),
                subscriptionStatus: status,
                loading: false,
                error: null,
                offerings: const [],
                purchasing: false,
                onPurchasePackage: (_) {},
                onRestorePurchases: () {},
                onReloadOfferings: () {},
                onManageSubscription: null,
                formatDate: (d) => d.toIso8601String(),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manage_subscription_button')), findsNothing);
    expect(
      find.byKey(const Key('manage_subscription_disabled_button')),
      findsOneWidget,
    );
    expect(find.text(l.subscriptionManagementNoUrl), findsOneWidget);
  });
}
