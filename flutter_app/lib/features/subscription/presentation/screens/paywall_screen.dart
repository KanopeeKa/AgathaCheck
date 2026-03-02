import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../../data/services/revenuecat_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    if (kIsWeb) {
      setState(() {
        _loading = false;
        _error = 'Subscriptions are available on the mobile app.';
      });
      return;
    }

    try {
      final service = ref.read(revenueCatServiceProvider);
      final offerings = await service.getOfferings();
      if (mounted) {
        setState(() {
          _offerings = offerings;
          _loading = false;
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

  Future<void> _presentPaywall() async {
    try {
      await RevenueCatUI.presentPaywall();
      await ref.read(subscriptionStatusProvider.notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open subscription options: $e')),
        );
      }
    }
  }

  Future<void> _presentCustomerCenter() async {
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open subscription management: $e')),
        );
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _loading = true);
    try {
      await ref.read(subscriptionStatusProvider.notifier).restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored successfully')),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
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
                        ? 'Agatha Check Unlimited'
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
                                      color:
                                          theme.colorScheme.onErrorContainer),
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
                    if (!kIsWeb) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const Key('subscribe_button'),
                          onPressed: _presentPaywall,
                          icon: const Icon(Icons.workspace_premium),
                          label: const Text('View Plans'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          key: const Key('restore_purchases_button'),
                          onPressed: _restorePurchases,
                          child: const Text('Restore Purchases'),
                        ),
                      ),
                    ],
                  ],
                  if (subscriptionStatus.hasUnlimited && !kIsWeb) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('manage_subscription_button'),
                        onPressed: _presentCustomerCenter,
                        icon: const Icon(Icons.settings),
                        label: const Text('Manage Subscription'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        key: const Key('restore_purchases_button'),
                        onPressed: _restorePurchases,
                        child: const Text('Restore Purchases'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agatha Check Unlimited',
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
