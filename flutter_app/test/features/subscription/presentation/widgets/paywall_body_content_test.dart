import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/subscription/domain/entities/subscription_status.dart';
import 'package:pet_profile_app/features/subscription/presentation/widgets/paywall_body_content.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('shows manage subscription when URL is available', (tester) async {
    var manageTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: PaywallBodyContent(
                theme: Theme.of(context),
                subscriptionStatus: const SubscriptionStatus(
                  tier: SubscriptionTier.unlimited,
                  isActive: true,
                  managementUrl: 'https://apps.apple.com/account/subscriptions',
                ),
                loading: false,
                error: null,
                offerings: const [],
                purchasing: false,
                onPurchasePackage: (_) {},
                onRestorePurchases: () {},
                onReloadOfferings: () {},
                onManageSubscription: () => manageTapped = true,
                formatDate: (d) => d.toString(),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manage_subscription_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('manage_subscription_button')));
    expect(manageTapped, isTrue);
  });

  testWidgets('shows explanation when unlimited without management URL', (
    tester,
  ) async {
    final contextElement = await _pumpUnlimitedBody(
      tester,
      managementUrl: null,
      onManage: null,
    );
    final l = AppLocalizations.of(contextElement)!;

    expect(find.byKey(const Key('manage_subscription_button')), findsNothing);
    expect(find.text(l.subscriptionManagementUnavailable), findsOneWidget);
  });
}

Future<Element> _pumpUnlimitedBody(
  WidgetTester tester, {
  required String? managementUrl,
  required VoidCallback? onManage,
}) async {
  late Element contextElement;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          contextElement = context as Element;
          return Scaffold(
            body: PaywallBodyContent(
              theme: Theme.of(context),
              subscriptionStatus: SubscriptionStatus(
                tier: SubscriptionTier.unlimited,
                isActive: true,
                managementUrl: managementUrl,
              ),
              loading: false,
              error: null,
              offerings: const [],
              purchasing: false,
              onPurchasePackage: (_) {},
              onRestorePurchases: () {},
              onReloadOfferings: () {},
              onManageSubscription: onManage,
              formatDate: (d) => d.toString(),
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return contextElement;
}
