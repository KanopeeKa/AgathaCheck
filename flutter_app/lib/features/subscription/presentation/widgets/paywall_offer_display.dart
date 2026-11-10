import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../l10n/app_localizations.dart';

/// Localized paywall copy derived from store product metadata (testable without [StoreProduct]).
@immutable
class PaywallOfferDisplay {
  const PaywallOfferDisplay({
    required this.title,
    required this.priceString,
    required this.recurringCadenceLabel,
    required this.autoRenewLine,
    required this.cancelLine,
    this.introductoryLine,
    this.savingsTag,
  });

  final String title;
  final String priceString;
  final String recurringCadenceLabel;
  final String autoRenewLine;
  final String cancelLine;
  final String? introductoryLine;
  final String? savingsTag;

  factory PaywallOfferDisplay.fromStoreProduct({
    required StoreProduct product,
    required AppLocalizations l,
    String? fallbackTitle,
    String? savingsTag,
  }) {
    final cadence = _cadenceLabel(product, l);
    return PaywallOfferDisplay(
      title: product.title.isNotEmpty ? product.title : (fallbackTitle ?? ''),
      priceString: product.priceString,
      recurringCadenceLabel: cadence,
      autoRenewLine: l.subscriptionAutoRenewDisclosure(product.priceString, cadence),
      cancelLine: l.subscriptionCancelDisclosure,
      introductoryLine: _introductoryLine(product.introductoryPrice, l),
      savingsTag: savingsTag,
    );
  }

  static String? _introductoryLine(IntroductoryPrice? intro, AppLocalizations l) {
    if (intro == null) return null;
    final unitLabel = _periodUnitLabel(intro.periodUnit, intro.periodNumberOfUnits, l);
    if (unitLabel == null) return null;
    return l.subscriptionIntroductoryOffer(
      intro.priceString,
      unitLabel,
      intro.cycles,
    );
  }

  static String _cadenceLabel(StoreProduct product, AppLocalizations l) {
    final iso = product.subscriptionPeriod;
    if (iso != null && iso.isNotEmpty) {
      final parsed = _isoPeriodToCadence(iso, l);
      if (parsed != null) return parsed;
    }
    final id = product.identifier.toLowerCase();
    if (id.contains('year') || id.contains('annual')) {
      return l.subscriptionPeriodPerYear;
    }
    if (id.contains('month')) {
      return l.subscriptionPeriodPerMonth;
    }
    return l.subscriptionPeriodRecurring;
  }

  static String? _isoPeriodToCadence(String iso, AppLocalizations l) {
    final match = RegExp(r'^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?$').firstMatch(iso);
    if (match == null) return null;
    final years = int.tryParse(match.group(1) ?? '') ?? 0;
    final months = int.tryParse(match.group(2) ?? '') ?? 0;
    final weeks = int.tryParse(match.group(3) ?? '') ?? 0;
    final days = int.tryParse(match.group(4) ?? '') ?? 0;
    if (years == 1 && months == 0 && weeks == 0 && days == 0) {
      return l.subscriptionPeriodPerYear;
    }
    if (months == 1 && years == 0 && weeks == 0 && days == 0) {
      return l.subscriptionPeriodPerMonth;
    }
    if (weeks == 1 && years == 0 && months == 0 && days == 0) {
      return l.subscriptionPeriodPerWeek;
    }
    if (months == 3) return l.subscriptionPeriodEveryMonths(3);
    if (months == 6) return l.subscriptionPeriodEveryMonths(6);
    if (months > 0) return l.subscriptionPeriodEveryMonths(months);
    if (years > 0) return l.subscriptionPeriodEveryYears(years);
    return l.subscriptionPeriodRecurring;
  }

  static String? _periodUnitLabel(PeriodUnit unit, int count, AppLocalizations l) {
    switch (unit) {
      case PeriodUnit.day:
        return count == 1 ? l.subscriptionIntroPeriodOneDay : l.subscriptionIntroPeriodDays(count);
      case PeriodUnit.week:
        return count == 1 ? l.subscriptionIntroPeriodOneWeek : l.subscriptionIntroPeriodWeeks(count);
      case PeriodUnit.month:
        return count == 1 ? l.subscriptionIntroPeriodOneMonth : l.subscriptionIntroPeriodMonths(count);
      case PeriodUnit.year:
        return count == 1 ? l.subscriptionIntroPeriodOneYear : l.subscriptionIntroPeriodYears(count);
      case PeriodUnit.unknown:
        return null;
    }
  }

  /// True when the annual package's monthly equivalent is lower than the monthly package.
  static bool annualIsBestValue({
    required Package? monthlyPackage,
    required Package? annualPackage,
  }) {
    if (monthlyPackage == null || annualPackage == null) return false;
    final monthly = monthlyPackage.storeProduct.price;
    if (monthly <= 0) return false;
    final annual = annualPackage.storeProduct;
    final annualMonthly =
        annual.pricePerMonth ?? (annual.price / 12);
    return annualMonthly < monthly;
  }

  static Package? findMonthlyPackage(List<Package> packages) {
    for (final p in packages) {
      final product = p.storeProduct;
      if (p.packageType == PackageType.monthly ||
          product.identifier.toLowerCase().contains('month')) {
        return p;
      }
    }
    return null;
  }

  static Package? findAnnualPackage(List<Package> packages) {
    for (final p in packages) {
      final product = p.storeProduct;
      if (p.packageType == PackageType.annual ||
          product.identifier.toLowerCase().contains('year') ||
          product.identifier.toLowerCase().contains('annual')) {
        return p;
      }
    }
    return null;
  }

  static bool packageIsAnnual(Package package) {
    final product = package.storeProduct;
    return package.packageType == PackageType.annual ||
        product.identifier.toLowerCase().contains('year') ||
        product.identifier.toLowerCase().contains('annual');
  }
}
