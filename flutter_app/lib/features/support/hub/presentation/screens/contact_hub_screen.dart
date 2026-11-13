import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/utils/external_link_launcher.dart';
import '../../../../../core/widgets/app_logo_title.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../support_contact_emails.dart';
import '../widgets/contact_hub_card.dart';

class ContactHubScreen extends StatelessWidget {
  const ContactHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    Future<void> launchMailbox(String email, String dialogTitle) async {
      final uri = Uri(scheme: 'mailto', path: email);
      await launchExternalLink(
        context,
        uri: uri,
        displayUrl: email,
        dialogTitle: dialogTitle,
      );
    }

    return Scaffold(
      appBar: AppBar(title: AppLogoTitle(title: l.contactHubTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            child: Text(
              l.contactHubSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
          ContactHubCard(
            semanticKey: const Key('contact_hub_help_support'),
            icon: Icons.support_agent_outlined,
            title: l.contactHubHelpSupportTitle,
            description: l.contactHubHelpSupportDescription,
            email: SupportContactEmails.support,
            onTap: () => context.push('/contact/support'),
          ),
          ContactHubCard(
            semanticKey: const Key('contact_hub_partnerships'),
            icon: Icons.handshake_outlined,
            title: l.contactHubPartnershipsTitle,
            description: l.contactHubPartnershipsDescription,
            email: SupportContactEmails.partnerships,
            onTap: () => launchMailbox(
              SupportContactEmails.partnerships,
              l.contactHubPartnershipsTitle,
            ),
          ),
          ContactHubCard(
            semanticKey: const Key('contact_hub_legal_privacy'),
            icon: Icons.gavel_outlined,
            title: l.contactHubLegalPrivacyTitle,
            description: l.contactHubLegalPrivacyDescription,
            email: SupportContactEmails.legal,
            onTap: () => launchMailbox(
              SupportContactEmails.legal,
              l.contactHubLegalPrivacyTitle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.contactHubMailboxesTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _MailboxLine(
            label: l.contactHubMailboxContact,
            email: SupportContactEmails.contact,
            onTap: () => launchMailbox(
              SupportContactEmails.contact,
              l.contactHubMailboxContact,
            ),
          ),
          _MailboxLine(
            label: l.contactHubMailboxSupport,
            email: SupportContactEmails.support,
            onTap: () => launchMailbox(
              SupportContactEmails.support,
              l.contactHubMailboxSupport,
            ),
          ),
          _MailboxLine(
            label: l.contactHubMailboxLegal,
            email: SupportContactEmails.legal,
            onTap: () => launchMailbox(
              SupportContactEmails.legal,
              l.contactHubMailboxLegal,
            ),
          ),
          _MailboxLine(
            label: l.contactHubMailboxPartnerships,
            email: SupportContactEmails.partnerships,
            onTap: () => launchMailbox(
              SupportContactEmails.partnerships,
              l.contactHubMailboxPartnerships,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.contactHubGeneralLine(SupportContactEmails.contact),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _MailboxLine extends StatelessWidget {
  const _MailboxLine({
    required this.label,
    required this.email,
    required this.onTap,
  });

  final String label;
  final String email;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: '$label $email',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
