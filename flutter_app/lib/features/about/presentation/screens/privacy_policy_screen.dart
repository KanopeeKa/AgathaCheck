import 'package:flutter/material.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: AppLogoTitle(title: l10n.privacyPolicy)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: SelectableText.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                children: [
                  TextSpan(
                    text: '${l10n.privacyPolicy}\n\n',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  TextSpan(
                    text: 'Agatha Track\n\n',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  _sectionTitle(theme, '1. ${l10n.ppDataController}'),
                  TextSpan(text: '${l10n.ppDataControllerDesc}\n\n'),
                  _sectionTitle(theme, '2. ${l10n.ppScope}'),
                  TextSpan(text: '${l10n.ppScopeDesc}\n\n'),
                  _sectionTitle(theme, '3. ${l10n.ppDataCollected}'),
                  TextSpan(text: '${l10n.ppDataCollectedDesc}\n\n'),
                  _sectionTitle(theme, '4. ${l10n.ppLegalBasis}'),
                  TextSpan(text: '${l10n.ppLegalBasisDesc}\n\n'),
                  _sectionTitle(theme, '5. ${l10n.ppHowWeUse}'),
                  TextSpan(text: '${l10n.ppHowWeUseDesc}\n\n'),
                  _sectionTitle(theme, '6. ${l10n.ppDataSharing}'),
                  TextSpan(text: '${l10n.ppDataSharingDesc}\n\n'),
                  _sectionTitle(theme, '7. ${l10n.ppInternationalTransfers}'),
                  TextSpan(text: '${l10n.ppInternationalTransfersDesc}\n\n'),
                  _sectionTitle(theme, '8. ${l10n.ppDataRetention}'),
                  TextSpan(text: '${l10n.ppDataRetentionDesc}\n\n'),
                  _sectionTitle(theme, '9. ${l10n.ppYourRights}'),
                  TextSpan(text: '${l10n.ppYourRightsDesc}\n\n'),
                  _sectionTitle(theme, '10. ${l10n.ppCookies}'),
                  TextSpan(text: '${l10n.ppCookiesDesc}\n\n'),
                  _sectionTitle(theme, '11. ${l10n.ppChildrensData}'),
                  TextSpan(text: '${l10n.ppChildrensDataDesc}\n\n'),
                  _sectionTitle(theme, '12. ${l10n.ppSecurity}'),
                  TextSpan(text: '${l10n.ppSecurityDesc}\n\n'),
                  _sectionTitle(theme, '13. ${l10n.ppChanges}'),
                  TextSpan(text: '${l10n.ppChangesDesc}\n\n'),
                  _sectionTitle(theme, '14. ${l10n.ppContact}'),
                  TextSpan(text: '${l10n.ppContactDesc}\n'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextSpan _sectionTitle(ThemeData theme, String text) {
    return TextSpan(
      text: '$text\n',
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        height: 2.0,
      ),
    );
  }
}
