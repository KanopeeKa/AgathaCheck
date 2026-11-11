import 'package:flutter/foundation.dart';
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

  bool get isLifetimeBilling =>
      packageType == PackageType.lifetime ||
      identifier.contains('lifetime') ||
      identifier.contains('life_time');

  bool get isYearlyBilling =>
      !isLifetimeBilling &&
      (subscriptionPeriodIso == 'P1Y' ||
          packageType == PackageType.annual ||
          _idOrTypeContainsYearly);

  bool get isMonthlyBilling =>
      !isLifetimeBilling &&
      (subscriptionPeriodIso == 'P1M' ||
          packageType == PackageType.monthly ||
          _idOrTypeContainsMonthly);

  bool get isWeeklyBilling =>
      !isLifetimeBilling &&
      (subscriptionPeriodIso == 'P1W' || packageType == PackageType.weekly);

  bool get _idOrTypeContainsYearly =>
      identifier.contains('yearly') || identifier.contains('annual');

  bool get _idOrTypeContainsMonthly => identifier.contains('monthly');

  /// Recurring price normalized to one month when the cadence is known.
  double? get monthlyEquivalentPrice {
    if (isLifetimeBilling) return null;
    if (isMonthlyBilling) return price;
    if (isYearlyBilling) return price / 12;
    if (isWeeklyBilling) return price * (52 / 12);
    final parsed = _parseSubscriptionPeriodIso(subscriptionPeriodIso);
    if (parsed == null) return null;
    return switch (parsed.unit) {
      _IsoPeriodUnit.day => price * (365 / parsed.count / 12),
      _IsoPeriodUnit.week => price * (52 / parsed.count / 12),
      _IsoPeriodUnit.month => price / parsed.count,
      _IsoPeriodUnit.year => price / (12 * parsed.count),
    };
  }
}

enum _IsoPeriodUnit { day, week, month, year }

class _ParsedIsoPeriod {
  const _ParsedIsoPeriod(this.count, this.unit);

  final int count;
  final _IsoPeriodUnit unit;
}

_ParsedIsoPeriod? _parseSubscriptionPeriodIso(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final match = RegExp(r'^P(\d+)(Y|M|W|D)$').firstMatch(iso);
  if (match == null) return null;
  final count = int.tryParse(match.group(1)!);
  if (count == null || count < 1) return null;
  final unit = switch (match.group(2)) {
    'D' => _IsoPeriodUnit.day,
    'W' => _IsoPeriodUnit.week,
    'M' => _IsoPeriodUnit.month,
    'Y' => _IsoPeriodUnit.year,
    _ => null,
  };
  if (unit == null) return null;
  return _ParsedIsoPeriod(count, unit);
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
      billingOnWeb: kIsWeb,
    );
  }

  static List<PaywallOfferDisplay> displaysForProductFacts(
    List<PaywallOfferProductFacts> facts,
    AppLocalizations l, {
    bool billingOnWeb = false,
  }) {
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
            billingOnWeb: billingOnWeb,
          ),
        )
        .toList();
  }

  static PaywallOfferDisplay fromProductFacts(
    PaywallOfferProductFacts facts,
    AppLocalizations l, {
    String? savingsTag,
    bool billingOnWeb = false,
  }) {
    final title = facts.title.isNotEmpty
        ? facts.title
        : (facts.isLifetimeBilling
              ? l.subscriptionFallbackLifetime
              : facts.isYearlyBilling
              ? l.subscriptionFallbackYearly
              : l.subscriptionFallbackMonthly);

    final cadence = _cadenceLabel(l, facts);

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

    final cancelLine = billingOnWeb
        ? l.subscriptionCancelDisclosureWeb
        : l.subscriptionCancelDisclosure;

    final autoRenewLine = facts.isLifetimeBilling
        ? l.subscriptionOneTimeDisclosure
        : l.subscriptionAutoRenewDisclosure;

    return PaywallOfferDisplay(
      title: title,
      price: facts.priceString,
      cadenceLabel: cadence,
      autoRenewLine: autoRenewLine,
      cancelLine: cancelLine,
      savingsTag: savingsTag,
      trialLine: trialLine,
    );
  }

  static String _cadenceLabel(
    AppLocalizations l,
    PaywallOfferProductFacts facts,
  ) {
    if (facts.isLifetimeBilling) return l.subscriptionPeriodLifetime;
    if (facts.isYearlyBilling) return l.subscriptionPeriodPerYear;
    if (facts.isMonthlyBilling) return l.subscriptionPeriodPerMonth;
    if (facts.isWeeklyBilling) return l.subscriptionPeriodPerWeek;
    final parsed = _parseSubscriptionPeriodIso(facts.subscriptionPeriodIso);
    if (parsed != null) {
      return switch (parsed.unit) {
        _IsoPeriodUnit.day => l.subscriptionCadenceDays(parsed.count),
        _IsoPeriodUnit.week => l.subscriptionCadenceWeeks(parsed.count),
        _IsoPeriodUnit.month => l.subscriptionCadenceMonths(parsed.count),
        _IsoPeriodUnit.year => l.subscriptionCadenceYears(parsed.count),
      };
    }
    return facts.subscriptionPeriodIso?.isNotEmpty == true
        ? l.subscriptionPeriodBillingPeriod
        : '';
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
      PeriodUnit.unknown => l.subscriptionIntroPeriodUnknown,
    };
  }
}
