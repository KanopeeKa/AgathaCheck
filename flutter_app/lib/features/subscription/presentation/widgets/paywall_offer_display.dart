import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../l10n/app_localizations.dart';

/// Plain store facts for tests and display mapping (no [StoreProduct] in tests).
class PaywallIntroductoryPriceFacts {
  const PaywallIntroductoryPriceFacts({
    required this.priceString,
    required this.cycles,
    required this.periodUnit,
    required this.periodNumberOfUnits,
    required this.periodIso,
  });

  final String priceString;
  final int cycles;
  final PeriodUnit periodUnit;
  final int periodNumberOfUnits;
  final String periodIso;

  factory PaywallIntroductoryPriceFacts.fromIntroductoryPrice(
    IntroductoryPrice intro,
  ) {
    return PaywallIntroductoryPriceFacts(
      priceString: intro.priceString,
      cycles: intro.cycles,
      periodUnit: intro.periodUnit,
      periodNumberOfUnits: intro.periodNumberOfUnits,
      periodIso: intro.period,
    );
  }
}

/// Plain product facts used to build [PaywallOfferDisplay].
class PaywallOfferProductFacts {
  const PaywallOfferProductFacts({
    required this.identifier,
    required this.title,
    required this.priceString,
    required this.price,
    this.subscriptionPeriodIso,
    this.packageType,
    this.introductoryPrice,
  });

  final String identifier;
  final String title;
  final String priceString;
  final double price;
  final String? subscriptionPeriodIso;
  final PackageType? packageType;
  final PaywallIntroductoryPriceFacts? introductoryPrice;

  factory PaywallOfferProductFacts.fromPackage(Package package) {
    final product = package.storeProduct;
    return PaywallOfferProductFacts(
      identifier: product.identifier,
      title: product.title,
      priceString: product.priceString,
      price: product.price,
      subscriptionPeriodIso: product.subscriptionPeriod,
      packageType: package.packageType,
      introductoryPrice: product.introductoryPrice != null
          ? PaywallIntroductoryPriceFacts.fromIntroductoryPrice(
              product.introductoryPrice!,
            )
          : null,
    );
  }

  bool get isYearlyBilling =>
      subscriptionPeriodIso == 'P1Y' ||
      packageType == PackageType.annual ||
      _idOrTypeContainsYearly;

  bool get isMonthlyBilling =>
      subscriptionPeriodIso == 'P1M' ||
      packageType == PackageType.monthly ||
      _idOrTypeContainsMonthly;

  bool get _idOrTypeContainsYearly =>
      identifier.contains('yearly') || identifier.contains('annual');

  bool get _idOrTypeContainsMonthly => identifier.contains('monthly');

  /// Recurring price normalized to one month when the cadence is known.
  double? get monthlyEquivalentPrice {
    if (isMonthlyBilling) return price;
    if (isYearlyBilling) return price / 12;
    return null;
  }
}

/// Localized paywall copy derived from store product data.
class PaywallOfferDisplay {
  const PaywallOfferDisplay({
    required this.title,
    required this.price,
    required this.cadenceLabel,
    required this.autoRenewLine,
    required this.cancelLine,
    this.savingsTag,
    this.trialLine,
  });

  final String title;
  final String price;
  final String cadenceLabel;
  final String autoRenewLine;
  final String cancelLine;
  final String? savingsTag;
  final String? trialLine;

  static List<PaywallOfferDisplay> displaysForPackages(
    List<Package> packages,
    AppLocalizations l,
  ) {
    return displaysForProductFacts(
      packages.map(PaywallOfferProductFacts.fromPackage).toList(),
      l,
    );
  }

  static List<PaywallOfferDisplay> displaysForProductFacts(
    List<PaywallOfferProductFacts> facts,
    AppLocalizations l,
  ) {
    final monthlyPrice = facts
        .where((f) => f.isMonthlyBilling)
        .map((f) => f.price)
        .firstOrNull;
    final annualMonthly = facts
        .where((f) => f.isYearlyBilling)
        .map((f) => f.monthlyEquivalentPrice)
        .whereType<double>()
        .firstOrNull;
    final showAnnualBestValue =
        monthlyPrice != null &&
        annualMonthly != null &&
        annualMonthly < monthlyPrice &&
        facts.where((f) => f.isMonthlyBilling).length == 1 &&
        facts.where((f) => f.isYearlyBilling).length == 1;

    return facts
        .map(
          (f) => fromProductFacts(
            f,
            l,
            savingsTag: showAnnualBestValue && f.isYearlyBilling
                ? l.subscriptionBestValue
                : null,
          ),
        )
        .toList();
  }

  static PaywallOfferDisplay fromProductFacts(
    PaywallOfferProductFacts facts,
    AppLocalizations l, {
    String? savingsTag,
  }) {
    final title = facts.title.isNotEmpty
        ? facts.title
        : (facts.isYearlyBilling
              ? l.subscriptionFallbackYearly
              : l.subscriptionFallbackMonthly);

    final cadence = facts.isYearlyBilling
        ? l.subscriptionPeriodPerYear
        : facts.isMonthlyBilling
        ? l.subscriptionPeriodPerMonth
        : '';

    String? trialLine;
    final intro = facts.introductoryPrice;
    if (intro != null) {
      final introPeriod = _introPeriodLabel(l, intro);
      trialLine = l.subscriptionTrialDisclosure(
        intro.priceString,
        introPeriod,
        facts.priceString,
      );
    }

    return PaywallOfferDisplay(
      title: title,
      price: facts.priceString,
      cadenceLabel: cadence,
      autoRenewLine: l.subscriptionAutoRenewDisclosure,
      cancelLine: l.subscriptionCancelDisclosure,
      savingsTag: savingsTag,
      trialLine: trialLine,
    );
  }

  static String _introPeriodLabel(
    AppLocalizations l,
    PaywallIntroductoryPriceFacts intro,
  ) {
    final total = intro.cycles * intro.periodNumberOfUnits;
    return switch (intro.periodUnit) {
      PeriodUnit.day => l.subscriptionIntroDays(total),
      PeriodUnit.week => l.subscriptionIntroWeeks(total),
      PeriodUnit.month => l.subscriptionIntroMonths(total),
      PeriodUnit.year => l.subscriptionIntroYears(total),
      PeriodUnit.unknown => intro.periodIso,
    };
  }
}
