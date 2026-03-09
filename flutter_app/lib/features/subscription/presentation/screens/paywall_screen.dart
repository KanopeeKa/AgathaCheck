import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/subscription_providers.dart';

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

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final service = ref.read(revenueCatServiceProvider);
      final offerings = await service.getOfferings();
      if (mounted) {
        setState(() {
          _offerings = offerings;
          _loading = false;
          if (offerings.isEmpty) {
            _error = 'No subscription plans are available at the moment. Please try again later.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load subscription options. Please try again.';
          _loading = false;
        });
      }
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
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _purchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
        );
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _loading = true);
    try {
      await ref.read(subscriptionStatusProvider.notifier).restorePurchases();
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.purchasesRestored)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not restore purchases: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(title: l.subscriptionTitle),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                            ? Colors.amber
                            : theme.colorScheme.primary,
                        semanticLabel: subscriptionStatus.hasUnlimited
                            ? 'Active subscription'
                            : 'Free plan',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        subscriptionStatus.hasUnlimited
                            ? 'Agatha Track Unlimited'
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
                          'Renews: ${_formatDate(subscriptionStatus.expirationDate!)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Card(
                            color: theme.colorScheme.errorContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: theme.colorScheme.onErrorContainer),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: TextStyle(
                                          color: theme
                                              .colorScheme.onErrorContainer),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (!subscriptionStatus.hasUnlimited) ...[
                        _buildFeatureCard(theme),
                        const SizedBox(height: 24),
                        ..._buildOfferingCards(theme),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            key: const Key('restore_purchases_button'),
                            onPressed: _restorePurchases,
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
                              onPressed: () {
                              },
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
                            onPressed: _restorePurchases,
                            child: Text(l.restorePurchases),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  List<Widget> _buildOfferingCards(ThemeData theme) {
    final l = AppLocalizations.of(context)!;
    final widgets = <Widget>[];

    for (final offering in _offerings) {
      for (final package in offering.availablePackages) {
        final product = package.storeProduct;
        final isMonthly = product.identifier.contains('monthly') ||
            package.packageType == PackageType.monthly;
        final isYearly = product.identifier.contains('yearly') ||
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
            child: _OfferingCard(
              title: product.title.isNotEmpty ? product.title : (isYearly ? 'Yearly' : 'Monthly'),
              price: product.priceString,
              periodLabel: periodLabel,
              savingsTag: savingsTag,
              isPurchasing: _purchasing,
              onPurchase: () => _purchasePackage(package),
              theme: theme,
            ),
          ),
        );
      }
    }

    if (widgets.isEmpty && _error == null) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('subscribe_button'),
              onPressed: _loading ? null : _loadOfferings,
              icon: const Icon(Icons.refresh),
              label: Text(l.loadPlans),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildFeatureCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agatha Track Unlimited',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _featureRow(Icons.pets, 'Unlimited pet profiles'),
            _featureRow(Icons.health_and_safety, 'Full health tracking'),
            _featureRow(Icons.share, 'Pet sharing with family'),
            _featureRow(Icons.picture_as_pdf, 'PDF report generation'),
            _featureRow(Icons.notifications_active, 'Health reminders'),
            _featureRow(Icons.support_agent, 'Priority support'),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _OfferingCard extends StatelessWidget {
  final String title;
  final String price;
  final String periodLabel;
  final String? savingsTag;
  final bool isPurchasing;
  final VoidCallback onPurchase;
  final ThemeData theme;

  const _OfferingCard({
    required this.title,
    required this.price,
    required this.periodLabel,
    this.savingsTag,
    required this.isPurchasing,
    required this.onPurchase,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Card(
      elevation: savingsTag != null ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: savingsTag != null
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: savingsTag != null ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isPurchasing ? null : onPurchase,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (savingsTag != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    savingsTag!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (periodLabel.isNotEmpty)
                          Text(
                            periodLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    price,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isPurchasing ? null : onPurchase,
                  child: isPurchasing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l.subscribe),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
