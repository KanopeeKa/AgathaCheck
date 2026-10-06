import 'package:flutter/material.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Subscription package card on the paywall screen.
class PaywallOfferingCard extends StatelessWidget {
  const PaywallOfferingCard({
    super.key,
    required this.title,
    required this.price,
    required this.periodLabel,
    this.savingsTag,
    required this.isPurchasing,
    required this.onPurchase,
    required this.theme,
  });

  final String title;
  final String price;
  final String periodLabel;
  final String? savingsTag;
  final bool isPurchasing;
  final VoidCallback onPurchase;
  final ThemeData theme;

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
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
