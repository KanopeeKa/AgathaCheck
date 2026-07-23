import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../core/widgets/branded_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/legal_document_id.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget _buildLogo({required double size}) {
    return BrandedLogo(size: size, useJpg: true, clipOval: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final legalDocuments = [
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
      appBar: AppBar(title: AppLogoTitle(title: l10n.aboutUs)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildLogo(size: 120),
                const SizedBox(height: 20),
                Text(
                  l10n.appTitle,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.appTagline,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.appDescription,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.legalInformation,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.legalDocumentsIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                for (final document in legalDocuments) ...[
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/legal'),
                    icon: const Icon(Icons.folder_open_outlined),
                    label: Text(l10n.viewAllLegalDocuments),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.appVersion,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
