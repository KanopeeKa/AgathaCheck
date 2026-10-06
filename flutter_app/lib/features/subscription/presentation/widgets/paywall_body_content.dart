import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/features/subscription/domain/entities/subscription_status.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'paywall_feature_list_card.dart';
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
  final String Function(DateTime date) formatDate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
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
                    ? 'Active subscription'
                    : 'Free plan',
              ),
              const SizedBox(height: 16),
              Text(
                subscriptionStatus.hasUnlimited
                    ? 'AgathaTrack Unlimited'
                    : 'Free Plan',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subscriptionStatus.hasUnlimited
                    ? 'You have full access to all features.'
                    : 'Upgrade to unlock all features.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (subscriptionStatus.expirationDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Renews: ${formatDate(subscriptionStatus.expirationDate!)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              error!,
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (!subscriptionStatus.hasUnlimited) ...[
                PaywallFeatureListCard(theme: theme),
                const SizedBox(height: 24),
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
                if (subscriptionStatus.managementUrl != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('manage_subscription_button'),
                      onPressed: () {},
                      icon: const Icon(Icons.settings),
                      label: Text(l.manageSubscription),
                    ),
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

    for (final offering in offerings) {
      for (final package in offering.availablePackages) {
        final product = package.storeProduct;
        final isMonthly =
            product.identifier.contains('monthly') ||
            package.packageType == PackageType.monthly;
        final isYearly =
            product.identifier.contains('yearly') ||
            package.packageType == PackageType.annual;

        String periodLabel;
        if (isYearly) {
          periodLabel = 'per year';
        } else if (isMonthly) {
          periodLabel = 'per month';
        } else {
          periodLabel = '';
        }

        final savingsTag = isYearly ? 'Best Value' : null;

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PaywallOfferingCard(
              title: product.title.isNotEmpty
                  ? product.title
                  : (isYearly ? 'Yearly' : 'Monthly'),
              price: product.priceString,
              periodLabel: periodLabel,
              savingsTag: savingsTag,
              isPurchasing: purchasing,
              onPurchase: () => onPurchasePackage(package),
              theme: theme,
            ),
          ),
        );
      }
    }

    if (widgets.isEmpty && error == null) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('subscribe_button'),
              onPressed: loading ? null : onReloadOfferings,
              icon: const Icon(Icons.refresh),
              label: Text(l.loadPlans),
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}
