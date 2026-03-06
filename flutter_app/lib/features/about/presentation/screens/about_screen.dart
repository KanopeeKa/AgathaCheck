import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../core/widgets/web_image.dart';
import '../../../../l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget _buildLogo(ThemeData theme, {required double size}) {
    final fallback = Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(Icons.pets, size: size * 0.55, color: theme.colorScheme.primary),
      ),
    );

    return Semantics(
      label: 'Agatha Track logo',
      child: kIsWeb
          ? WebAssetImage(
              assetPath: 'assets/logo.jpg',
              height: size,
              width: size,
              fit: BoxFit.cover,
              fallback: fallback,
              clipOval: true,
            )
          : ClipOval(
              child: Image.asset(
                'assets/logo.jpg',
                height: size,
                width: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
                _buildLogo(theme, size: 120),
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
                Card(
                  child: ListTile(
                    leading: Icon(Icons.privacy_tip_outlined, color: theme.colorScheme.primary),
                    title: Text(l10n.privacyPolicy),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/privacy-policy'),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.gavel_outlined, color: theme.colorScheme.primary),
                    title: Text(l10n.termsOfService),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/terms-of-service'),
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
