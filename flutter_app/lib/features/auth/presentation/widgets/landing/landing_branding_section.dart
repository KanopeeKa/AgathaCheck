import 'package:flutter/material.dart';

import '../../../../../core/theme/experience_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import 'landing_logo.dart';
import 'landing_path_card.dart';

class LandingBrandingSection extends StatelessWidget {
  const LandingBrandingSection({
    super.key,
    required this.theme,
    required this.l10n,
  });

  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final xp = theme.extension<ExperienceColors>() ?? ExperienceColors.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        buildLandingLogo(theme, size: 120),
        const SizedBox(height: 20),
        Text(
          l10n.appTitle,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          label: 'App tagline',
          child: Text(
            l10n.appTagline,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.appDescription,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        LandingPathCard(
          key: const Key('landing_guardian_path_card'),
          summary: l10n.landingGuardianPathSummary,
          expandLabel: l10n.landingGuardianPathExpandCta,
          collapseLabel: l10n.landingGuardianPathCollapseCta,
          detail: l10n.landingGuardianPathDetail,
          accentColor: xp.guardianPrimary,
          onAccentColor: xp.guardianOnPrimary,
          icon: Icons.pets,
        ),
        const SizedBox(height: 12),
        LandingPathCard(
          key: const Key('landing_org_path_card'),
          summary: l10n.landingOrgPathSummary,
          expandLabel: l10n.landingOrgPathExpandCta,
          collapseLabel: l10n.landingOrgPathCollapseCta,
          detail: l10n.landingOrgPathDetail,
          accentColor: xp.organizationPrimary,
          onAccentColor: xp.organizationOnPrimary,
          icon: Icons.business_outlined,
        ),
      ],
    );
  }
}
