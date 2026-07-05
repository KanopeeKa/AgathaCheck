import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/legal_document_id.dart';

class LegalDocumentsScreen extends StatelessWidget {
  const LegalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final documents = [
      (
        id: LegalDocumentId.termsOfUse,
        title: l10n.termsOfService,
        icon: Icons.gavel_outlined,
      ),
      (
        id: LegalDocumentId.privacyNotice,
        title: l10n.privacyPolicy,
        icon: Icons.privacy_tip_outlined,
      ),
      (
        id: LegalDocumentId.legalNotice,
        title: l10n.legalNotice,
        icon: Icons.info_outline,
      ),
      (
        id: LegalDocumentId.dataProcessingAddendum,
        title: l10n.dataProcessingAddendum,
        icon: Icons.description_outlined,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: AppLogoTitle(title: l10n.legalInformation)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.legalDocumentsIntro,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                for (final document in documents) ...[
                  Card(
                    child: ListTile(
                      leading: Icon(
                        document.icon,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(document.title),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(document.id.routePath),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
