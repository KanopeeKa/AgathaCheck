import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/widgets/app_logo_title.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import '../../domain/entities/subscription_operation_outcomes.dart';
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
    final outcome = await ref
        .read(subscriptionStatusProvider.notifier)
        .purchasePackage(package);
    if (!mounted) return;
    setState(() => _purchasing = false);
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    switch (outcome.kind) {
      case PurchaseOutcomeKind.success:
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.welcomeUnlimited),
            backgroundColor: AppColorTokens.success,
          ),
        );
      case PurchaseOutcomeKind.cancelled:
        break;
      case PurchaseOutcomeKind.failed:
        messenger.showSnackBar(
          SnackBar(content: Text(l.subscriptionPurchaseFailed)),
        );
      case PurchaseOutcomeKind.pendingUnconfirmed:
        messenger.showSnackBar(
          SnackBar(content: Text(l.subscriptionPurchasePending)),
        );
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _loading = true);
    final outcome = await ref
        .read(subscriptionStatusProvider.notifier)
        .restorePurchases();
    if (!mounted) return;
    setState(() => _loading = false);
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    switch (outcome.kind) {
      case RestoreOutcomeKind.restored:
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.purchasesRestored),
            backgroundColor: AppColorTokens.success,
          ),
        );
      case RestoreOutcomeKind.nothingToRestore:
        messenger.showSnackBar(
          SnackBar(content: Text(l.subscriptionNothingToRestore)),
        );
      case RestoreOutcomeKind.failed:
        messenger.showSnackBar(
          SnackBar(content: Text(l.subscriptionRestoreFailed)),
        );
    }
  }

  Future<void> _manageSubscription() async {
    final url = ref.read(subscriptionStatusProvider).managementUrl;
    if (url == null || url.isEmpty) return;
    final l = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showManagementFallback(url, l);
      return;
    }
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showManagementFallback(url, l);
      }
    } catch (_) {
      if (mounted) _showManagementFallback(url, l);
    }
  }

  void _showManagementFallback(String url, AppLocalizations l) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l.manageSubscription),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.subscriptionManagementOpenFailed),
              const SizedBox(height: 12),
              SelectableText(url),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: url));
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.peopleCopiedToClipboard)),
                  );
                }
              },
              child: Text(l.copy),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l.ok),
            ),
          ],
        );
      },
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
