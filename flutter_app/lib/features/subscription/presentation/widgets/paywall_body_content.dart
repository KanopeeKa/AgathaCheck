import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/widgets/async_state/async_error_state.dart';
import 'package:pet_profile_app/core/widgets/async_state/labelled_progress.dart';
import 'package:pet_profile_app/core/widgets/async_state/supplemental_state_caption.dart';
import 'package:pet_profile_app/features/subscription/domain/entities/subscription_status.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'paywall_feature_list_card.dart';
import 'paywall_offer_display.dart';
import 'paywall_offering_card.dart';

/// Scrollable paywall content (presentational; no Riverpod).
class PaywallBodyContent extends StatelessWidget {
  const PaywallBodyContent({
    super.key,
    required this.theme,
    required this.subscriptionStatus,
    required this.loading,
    required this.error,
    required this.offerings,
    required this.purchasing,
    required this.onPurchasePackage,
    required this.onRestorePurchases,
    required this.onReloadOfferings,
    required this.onManageSubscription,
    required this.formatDate,
  });

  final ThemeData theme;
  final SubscriptionStatus subscriptionStatus;
  final bool loading;
  final String? error;
  final List<Offering> offerings;
  final bool purchasing;
  final void Function(Package package) onPurchasePackage;
  final VoidCallback onRestorePurchases;
  final VoidCallback onReloadOfferings;
  final VoidCallback? onManageSubscription;
  final String Function(DateTime date) formatDate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (loading) {
      return Center(child: LabelledProgress(label: l.loadingLabel));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                subscriptionStatus.hasUnlimited
                    ? Icons.workspace_premium
                    : Icons.star_outline,
                size: 64,
                color: subscriptionStatus.hasUnlimited
                    ? AppColorTokens.warmAccent
                    : theme.colorScheme.primary,
                semanticLabel: subscriptionStatus.hasUnlimited
                    ? l.subscriptionStatusActiveSemantic
                    : l.subscriptionStatusFreeSemantic,
              ),
              const SizedBox(height: 16),
              Text(
                subscriptionStatus.hasUnlimited
                    ? l.subscriptionProductNameUnlimited
                    : l.subscriptionProductNameFree,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subscriptionStatus.hasUnlimited
                    ? l.subscriptionBodyUnlimited
                    : l.subscriptionBodyFree,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (subscriptionStatus.expirationDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  subscriptionStatus.willRenew
                      ? l.subscriptionRenewsOn(
                          formatDate(subscriptionStatus.expirationDate!),
                        )
                      : l.subscriptionActiveUntil(
                          formatDate(subscriptionStatus.expirationDate!),
                        ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              if (!subscriptionStatus.hasUnlimited) ...[
                PaywallFeatureListCard(theme: theme),
                const SizedBox(height: 24),
                if (error != null)
                  AsyncErrorState(
                    title: error,
                    onRetry: onReloadOfferings,
                    retryKey: const Key('paywall_reload_offerings'),
                  )
                else
                  ..._offeringCards(context, l),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const Key('restore_purchases_button'),
                    onPressed: onRestorePurchases,
                    child: Text(l.restorePurchases),
                  ),
                ),
              ],
              if (subscriptionStatus.hasUnlimited) ...[
                if (onManageSubscription != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('manage_subscription_button'),
                      onPressed: onManageSubscription,
                      icon: const Icon(Icons.settings),
                      label: Text(l.manageSubscription),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  SupplementalStateCaption(
                    state: SupplementalState.unavailable,
                    label: l.subscriptionManagementUnavailable,
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const Key('restore_purchases_button'),
                    onPressed: onRestorePurchases,
                    child: Text(l.restorePurchases),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _offeringCards(BuildContext context, AppLocalizations l) {
    final widgets = <Widget>[];
    final packages = <Package>[];
    for (final offering in offerings) {
      packages.addAll(offering.availablePackages);
    }

    final displays = PaywallOfferDisplay.displaysForPackages(packages, l);
    for (var i = 0; i < packages.length; i++) {
      final package = packages[i];
      final display = displays[i];
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PaywallOfferingCard(
            offer: display,
            isPurchasing: purchasing,
            onPurchase: () => onPurchasePackage(package),
            theme: theme,
          ),
        ),
      );
    }

    return widgets;
  }
}
