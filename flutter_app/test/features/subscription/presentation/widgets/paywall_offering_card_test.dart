import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/subscription/presentation/widgets/paywall_offering_card.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('PaywallOfferingCard shows price and subscribe', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: PaywallOfferingCard(
                title: 'Monthly',
                price: '\$4.99',
                periodLabel: 'per month',
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

    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('\$4.99'), findsOneWidget);
  });
}
