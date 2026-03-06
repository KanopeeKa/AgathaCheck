import 'package:flutter/material.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: AppLogoTitle(title: l10n.termsOfService)),
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
                    text: '${l10n.termsOfService}\n\n',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  TextSpan(
                    text: 'Agatha Track\n\n',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  _sectionTitle(theme, '1. ${l10n.tosAcceptance}'),
                  TextSpan(text: '${l10n.tosAcceptanceDesc}\n\n'),
                  _sectionTitle(theme, '2. ${l10n.tosEligibility}'),
                  TextSpan(text: '${l10n.tosEligibilityDesc}\n\n'),
                  _sectionTitle(theme, '3. ${l10n.tosAccountSecurity}'),
                  TextSpan(text: '${l10n.tosAccountSecurityDesc}\n\n'),
                  _sectionTitle(theme, '4. ${l10n.tosServiceDescription}'),
                  TextSpan(text: '${l10n.tosServiceDescriptionDesc}\n\n'),
                  _sectionTitle(theme, '5. ${l10n.tosUserContent}'),
                  TextSpan(text: '${l10n.tosUserContentDesc}\n\n'),
                  _sectionTitle(theme, '6. ${l10n.tosProhibitedUses}'),
                  TextSpan(text: '${l10n.tosProhibitedUsesDesc}\n\n'),
                  _sectionTitle(theme, '7. ${l10n.tosSubscriptions}'),
                  TextSpan(text: '${l10n.tosSubscriptionsDesc}\n\n'),
                  _sectionTitle(theme, '8. ${l10n.tosIntellectualProperty}'),
                  TextSpan(text: '${l10n.tosIntellectualPropertyDesc}\n\n'),
                  _sectionTitle(theme, '9. ${l10n.tosLiability}'),
                  TextSpan(text: '${l10n.tosLiabilityDesc}\n\n'),
                  _sectionTitle(theme, '10. ${l10n.tosTermination}'),
                  TextSpan(text: '${l10n.tosTerminationDesc}\n\n'),
                  _sectionTitle(theme, '11. ${l10n.tosGoverningLaw}'),
                  TextSpan(text: '${l10n.tosGoverningLawDesc}\n\n'),
                  _sectionTitle(theme, '12. ${l10n.tosContact}'),
                  TextSpan(text: '${l10n.tosContactDesc}\n'),
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
