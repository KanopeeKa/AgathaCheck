import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/legal/legal_document_id.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'paywall_offer_display.dart';

/// Subscription package card on the paywall screen.
class PaywallOfferingCard extends StatelessWidget {
  const PaywallOfferingCard({
    super.key,
    required this.offer,
    required this.isPurchasing,
    required this.onPurchase,
    required this.theme,
  });

  final PaywallOfferDisplay offer;
  final bool isPurchasing;
  final VoidCallback onPurchase;
  final ThemeData theme;

  static const double _cardRadius = 16;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final outline = theme.colorScheme.outlineVariant;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(color: outline, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(_cardRadius),
        onTap: isPurchasing ? null : onPurchase,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (offer.savingsTag != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
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
                      offer.savingsTag!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
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
                          offer.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (offer.cadenceLabel.isNotEmpty)
                          Text(
                            offer.cadenceLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    offer.price,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                offer.autoRenewLine,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                offer.cancelLine,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (offer.trialLine != null) ...[
                const SizedBox(height: 4),
                Text(
                  offer.trialLine!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton(
                    onPressed: () =>
                        context.push(LegalDocumentId.termsOfUse.routePath),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(l.termsOfService),
                  ),
                  Text(
                    '·',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.push(LegalDocumentId.privacyNotice.routePath),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(l.privacyPolicy),
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
