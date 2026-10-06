import 'package:flutter/material.dart';

/// Unlimited plan feature list on the paywall screen.
class PaywallFeatureListCard extends StatelessWidget {
  const PaywallFeatureListCard({super.key, required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AgathaTrack Unlimited',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _featureRow(theme, Icons.pets, 'Unlimited pet profiles'),
            _featureRow(theme, Icons.health_and_safety, 'Full health tracking'),
            _featureRow(theme, Icons.share, 'Pet sharing with family'),
            _featureRow(theme, Icons.picture_as_pdf, 'PDF report generation'),
            _featureRow(theme, Icons.notifications_active, 'Health reminders'),
            _featureRow(theme, Icons.support_agent, 'Priority support'),
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
