import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:pet_profile_app/core/utils/external_link_launcher.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/widgets/app_logo_title.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import '../providers/subscription_providers.dart';
import '../widgets/paywall_body_content.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _loading = true;
  List<Offering> _offerings = [];
  String? _error;
  bool _purchasing = false;
  bool _offeringsInFlight = false;
  bool _offeringsRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_offeringsRequested) {
      _offeringsRequested = true;
      _loadOfferings();
    }
  }

  Future<void> _loadOfferings() async {
    if (!mounted || _offeringsInFlight) return;
    _offeringsInFlight = true;
    final l = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(revenueCatServiceProvider);
      final offerings = await service.getOfferings();
      if (mounted) {
        setState(() {
          _offerings = offerings;
          _loading = false;
          _error = offerings.isEmpty ? l.subscriptionPlansUnavailable : null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = l.subscriptionPlansUnavailable;
          _loading = false;
        });
      }
    } finally {
      _offeringsInFlight = false;
    }
  }

  Future<void> _purchasePackage(Package package) async {
    setState(() => _purchasing = true);
    try {
      final service = ref.read(revenueCatServiceProvider);
      final status = await service.purchasePackage(package);
      await ref.read(subscriptionStatusProvider.notifier).refresh();
      if (mounted) {
        setState(() => _purchasing = false);
        if (status.hasUnlimited) {
          final l = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.welcomeUnlimited),
              backgroundColor: AppColorTokens.success,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _purchasing = false);
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.subscriptionPurchaseFailed)));
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _loading = true);
    try {
      await ref.read(subscriptionStatusProvider.notifier).restorePurchases();
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.purchasesRestored)));
      }
    } catch (_) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.subscriptionRestoreFailed)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _manageSubscription() async {
    final url = ref.read(subscriptionStatusProvider).managementUrl;
    if (url == null || url.isEmpty) return;
    final l = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (mounted) {
        showExternalLinkFallback(
          context,
          url: url,
          dialogTitle: l.manageSubscription,
          failureMessage: l.subscriptionManagementOpenFailed,
        );
      }
      return;
    }
    if (!mounted) return;
    await launchExternalLink(
      context,
      uri: uri,
      displayUrl: url,
      dialogTitle: l.manageSubscription,
      failureMessage: l.subscriptionManagementOpenFailed,
    );
  }

  String _formatDate(DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);
    final l = AppLocalizations.of(context)!;

    final managementUrl = subscriptionStatus.managementUrl;
    final manageCallback =
        subscriptionStatus.hasUnlimited &&
            managementUrl != null &&
            managementUrl.isNotEmpty
        ? _manageSubscription
        : null;

    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(title: l.subscriptionTitle),
        centerTitle: true,
      ),
      body: PaywallBodyContent(
        theme: theme,
        subscriptionStatus: subscriptionStatus,
        loading: _loading,
        error: _error,
        offerings: _offerings,
        purchasing: _purchasing,
        onPurchasePackage: _purchasePackage,
        onRestorePurchases: _restorePurchases,
        onReloadOfferings: _loadOfferings,
        onManageSubscription: manageCallback,
        formatDate: _formatDate,
      ),
    );
  }
}
