import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/subscription/presentation/widgets/paywall_offer_display.dart';
import 'package:pet_profile_app/features/subscription/presentation/widgets/paywall_offering_card.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  test('annualIsBestValue false when only one cadence is present', () {
    expect(
      PaywallOfferDisplay.annualIsBestValue(
        monthlyPackage: null,
        annualPackage: null,
      ),
      isFalse,
    );
  });

  testWidgets('disclosure lines render from plain PaywallOfferDisplay DTO', (
    tester,
  ) async {
    late AppLocalizations l;
    const display = PaywallOfferDisplay(
      title: 'Monthly plan',
      priceString: '\$4.99',
      recurringCadenceLabel: 'per month',
      autoRenewLine: '\$4.99 per month. Auto-renews until you cancel.',
      cancelLine: 'Cancel anytime in your app store subscription settings.',
      introductoryLine: 'Introductory offer: \$0.99 for 1 week.',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l = AppLocalizations.of(context)!;
            return Scaffold(
              body: PaywallOfferingCard(
                display: display,
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

    expect(find.text(display.autoRenewLine), findsOneWidget);
    expect(find.text(display.cancelLine), findsOneWidget);
    expect(find.text(display.introductoryLine!), findsOneWidget);
    expect(find.text(l.termsOfService), findsOneWidget);
    expect(find.text(l.privacyPolicy), findsOneWidget);
    expect(find.text('Best value'), findsNothing);
  });
}
