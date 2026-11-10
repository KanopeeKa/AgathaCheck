import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/subscription/presentation/widgets/paywall_offer_display.dart';
import 'package:pet_profile_app/features/subscription/presentation/widgets/paywall_offering_card.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('PaywallOfferingCard shows price, disclosure, and subscribe', (
    tester,
  ) async {
    const offer = PaywallOfferDisplay(
      title: 'Monthly',
      price: '\$4.99',
      cadenceLabel: 'per month',
      autoRenewLine: 'Renews automatically.',
      cancelLine: 'Cancel in store settings.',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: PaywallOfferingCard(
                offer: offer,
                isPurchasing: false,
                onPurchase: () {},
                theme: Theme.of(context),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l = AppLocalizations.of(
      tester.element(find.byType(PaywallOfferingCard)),
    )!;

    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('\$4.99'), findsOneWidget);
    expect(find.text(l.subscribe), findsOneWidget);
    expect(find.text('Renews automatically.'), findsOneWidget);
  });
}
