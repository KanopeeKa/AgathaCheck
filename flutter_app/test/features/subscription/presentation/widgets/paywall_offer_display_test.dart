import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:pet_profile_app/features/subscription/presentation/widgets/paywall_offer_display.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PaywallOfferDisplay', () {
    late AppLocalizations l;

    setUp(() async {
      l = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('shows disclosure lines from plain product facts', () {
      const monthly = PaywallOfferProductFacts(
        identifier: 'monthly_prod',
        title: 'Unlimited Monthly',
        priceString: '\$4.99',
        price: 4.99,
        subscriptionPeriodIso: 'P1M',
        packageType: PackageType.monthly,
      );

      final display = PaywallOfferDisplay.fromProductFacts(monthly, l);

      expect(display.price, '\$4.99');
      expect(display.cadenceLabel, l.subscriptionPeriodPerMonth);
      expect(display.autoRenewLine, l.subscriptionAutoRenewDisclosure);
      expect(display.cancelLine, l.subscriptionCancelDisclosure);
      expect(display.trialLine, isNull);
    });

    test('shows trial line only when introductory price is present', () {
      const withTrial = PaywallOfferProductFacts(
        identifier: 'annual_trial',
        title: 'Unlimited Annual',
        priceString: '\$39.99',
        price: 39.99,
        subscriptionPeriodIso: 'P1Y',
        packageType: PackageType.annual,
        introductoryPrice: PaywallIntroductoryPriceFacts(
          priceString: '\$0.00',
          cycles: 1,
          periodUnit: PeriodUnit.month,
          periodNumberOfUnits: 1,
          periodIso: 'P1M',
        ),
      );

      final display = PaywallOfferDisplay.fromProductFacts(withTrial, l);

      expect(display.trialLine, isNotNull);
      expect(display.trialLine, contains('\$0.00'));
      expect(display.trialLine, contains('\$39.99'));
    });

    test('omits Best Value when only one cadence is offered', () {
      const monthly = PaywallOfferProductFacts(
        identifier: 'monthly_only',
        title: 'Monthly',
        priceString: '\$5.00',
        price: 5,
        subscriptionPeriodIso: 'P1M',
        packageType: PackageType.monthly,
      );

      final displays = PaywallOfferDisplay.displaysForProductFacts([
        monthly,
      ], l);

      expect(displays, hasLength(1));
      expect(displays.single.savingsTag, isNull);
    });

    test('uses weekly cadence from ISO period', () {
      const weekly = PaywallOfferProductFacts(
        identifier: 'weekly',
        title: 'Weekly',
        priceString: '\$2.00',
        price: 2,
        subscriptionPeriodIso: 'P1W',
        packageType: PackageType.weekly,
      );

      final display = PaywallOfferDisplay.fromProductFacts(weekly, l);

      expect(display.cadenceLabel, l.subscriptionPeriodPerWeek);
      expect(display.autoRenewLine, l.subscriptionAutoRenewDisclosure);
    });

    test('lifetime shows one-time disclosure and cadence', () {
      const lifetime = PaywallOfferProductFacts(
        identifier: 'lifetime',
        title: 'Lifetime',
        priceString: '\$199.00',
        price: 199,
        packageType: PackageType.lifetime,
      );

      final display = PaywallOfferDisplay.fromProductFacts(lifetime, l);

      expect(display.cadenceLabel, l.subscriptionPeriodLifetime);
      expect(display.autoRenewLine, l.subscriptionOneTimeDisclosure);
    });

    test('web billing uses web cancel copy', () {
      const monthly = PaywallOfferProductFacts(
        identifier: 'm',
        title: 'Monthly',
        priceString: '\$4.99',
        price: 4.99,
        subscriptionPeriodIso: 'P1M',
        packageType: PackageType.monthly,
      );

      final display = PaywallOfferDisplay.fromProductFacts(
        monthly,
        l,
        billingOnWeb: true,
      );

      expect(display.cancelLine, l.subscriptionCancelDisclosureWeb);
    });

    test('unknown introductory period uses localized placeholder', () {
      const withIntro = PaywallOfferProductFacts(
        identifier: 'trial',
        title: 'Monthly',
        priceString: '\$4.99',
        price: 4.99,
        subscriptionPeriodIso: 'P1M',
        introductoryPrice: PaywallIntroductoryPriceFacts(
          priceString: '\$0.00',
          cycles: 1,
          periodUnit: PeriodUnit.unknown,
          periodNumberOfUnits: 1,
          periodIso: 'P7D',
        ),
      );

      final display = PaywallOfferDisplay.fromProductFacts(withIntro, l);

      expect(display.trialLine, contains(l.subscriptionIntroPeriodUnknown));
      expect(display.trialLine, isNot(contains('P7D')));
    });

    test('parses multi-month ISO cadence', () {
      const quarterly = PaywallOfferProductFacts(
        identifier: 'q',
        title: 'Quarterly',
        priceString: '\$15.00',
        price: 15,
        subscriptionPeriodIso: 'P3M',
      );

      final display = PaywallOfferDisplay.fromProductFacts(quarterly, l);

      expect(display.cadenceLabel, l.subscriptionCadenceMonths(3));
    });

    test('shows Best Value when annual monthly cost beats monthly', () {
      const monthly = PaywallOfferProductFacts(
        identifier: 'm',
        title: 'Monthly',
        priceString: '\$6.00',
        price: 6,
        subscriptionPeriodIso: 'P1M',
        packageType: PackageType.monthly,
      );
      const annual = PaywallOfferProductFacts(
        identifier: 'y',
        title: 'Annual',
        priceString: '\$60.00',
        price: 60,
        subscriptionPeriodIso: 'P1Y',
        packageType: PackageType.annual,
      );

      final displays = PaywallOfferDisplay.displaysForProductFacts([
        monthly,
        annual,
      ], l);
      expect(displays[0].savingsTag, isNull);
      expect(displays[1].savingsTag, l.subscriptionBestValue);
    });
  });
}
