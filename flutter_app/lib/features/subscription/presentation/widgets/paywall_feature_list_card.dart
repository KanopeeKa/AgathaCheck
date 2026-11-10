import 'package:flutter/material.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Unlimited plan feature list on the paywall screen.
class PaywallFeatureListCard extends StatelessWidget {
  const PaywallFeatureListCard({super.key, required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.subscriptionPlanUnlimitedTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _featureRow(theme, Icons.pets, l.subscriptionFeatureUnlimitedPets),
            _featureRow(theme, Icons.health_and_safety, l.subscriptionFeatureHealthTracking),
            _featureRow(theme, Icons.share, l.subscriptionFeaturePetSharing),
            _featureRow(theme, Icons.picture_as_pdf, l.subscriptionFeaturePdfReports),
            _featureRow(theme, Icons.notifications_active, l.subscriptionFeatureReminders),
            _featureRow(theme, Icons.support_agent, l.subscriptionFeaturePrioritySupport),
          ],
        ),
      ),
    );
  }

  static Widget _featureRow(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
