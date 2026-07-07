import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Subscription, organizations and language cards shown on `MyDetailsScreen`.
class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({
    super.key,
    required this.theme,
    required this.l10n,
    required this.currentLocale,
    required this.onSubscription,
    required this.onOrganizations,
    required this.onLocaleChanged,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final String currentLocale;
  final VoidCallback onSubscription;
  final VoidCallback onOrganizations;
  final ValueChanged<String> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: ListTile(
            key: const Key('subscription_tile'),
            leading: Icon(
              Icons.workspace_premium,
              color: theme.colorScheme.primary,
            ),
            title: Text(l10n.subscription),
            subtitle: Text(l10n.managePlan),
            trailing: const Icon(Icons.chevron_right),
            onTap: onSubscription,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            key: const Key('organizations_tile'),
            leading: Icon(Icons.business, color: theme.colorScheme.primary),
            title: Text(l10n.myOrganizations),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOrganizations,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: DropdownButton<String>(
              value: currentLocale,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'fr', child: Text('Français')),
              ],
              onChanged: (value) {
                if (value != null) onLocaleChanged(value);
              },
            ),
          ),
        ),
      ],
    );
  }
}
