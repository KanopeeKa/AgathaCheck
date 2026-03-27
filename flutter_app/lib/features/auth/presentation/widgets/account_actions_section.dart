import 'package:flutter/material.dart';

class AccountActionsSection extends StatelessWidget {
  final ThemeData theme;
  final String l10nAboutUs;
  final String l10nExportMyData;
  final String l10nExportMyDataSubtitle;
  final String l10nConsentSettings;
  final String l10nConsentManagePreferences;
  final String l10nDeleteAccount;
  final String l10nDeleteAccountSubtitle;
  final VoidCallback onAbout;
  final VoidCallback onExport;
  final VoidCallback onConsent;
  final VoidCallback onDelete;

  const AccountActionsSection({
    super.key,
    required this.theme,
    required this.l10nAboutUs,
    required this.l10nExportMyData,
    required this.l10nExportMyDataSubtitle,
    required this.l10nConsentSettings,
    required this.l10nConsentManagePreferences,
    required this.l10nDeleteAccount,
    required this.l10nDeleteAccountSubtitle,
    required this.onAbout,
    required this.onExport,
    required this.onConsent,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
                title: Text(l10nAboutUs),
                trailing: const Icon(Icons.chevron_right),
                onTap: onAbout,
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.download, color: theme.colorScheme.primary),
                title: Text(l10nExportMyData),
                subtitle: Text(l10nExportMyDataSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: onExport,
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.cookie_outlined, color: theme.colorScheme.primary),
                title: Text(l10nConsentSettings),
                subtitle: Text(l10nConsentManagePreferences),
                trailing: const Icon(Icons.chevron_right),
                onTap: onConsent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.errorContainer.withAlpha(80),
          child: ListTile(
            leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
            title: Text(l10nDeleteAccount, style: TextStyle(color: theme.colorScheme.error)),
            subtitle: Text(l10nDeleteAccountSubtitle),
            trailing: Icon(Icons.chevron_right, color: theme.colorScheme.error),
            onTap: onDelete,
          ),
        ),
      ],
    );
  }
}
