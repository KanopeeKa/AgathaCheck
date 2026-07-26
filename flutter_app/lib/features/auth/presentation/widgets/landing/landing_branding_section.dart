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
    required this.onPetParentsPressed,
    required this.onCharitiesPressed,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final VoidCallback onPetParentsPressed;
  final VoidCallback onCharitiesPressed;

  @override
  Widget build(BuildContext context) {
    final xp = theme.extension<ExperienceColors>() ?? ExperienceColors.light;
    final isNarrow = MediaQuery.sizeOf(context).width <= 520;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        buildLandingLogo(theme, size: 120),
        const SizedBox(height: 20),
        Text(
          l10n.appTitle,
          textAlign: TextAlign.center,
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
            textAlign: TextAlign.center,
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
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        if (isNarrow)
          Column(
            children: [
              LandingPathCard(
                key: const Key('landing_guardian_path_card'),
                summary: l10n.landingGuardianPathSummary,
                actionLabel: l10n.landingPathScrollCta,
                accentColor: xp.guardianPrimary,
                onAccentColor: xp.guardianOnPrimary,
                icon: Icons.pets,
                onPressed: onPetParentsPressed,
              ),
              const SizedBox(height: 12),
              LandingPathCard(
                key: const Key('landing_org_path_card'),
                summary: l10n.landingOrgPathSummary,
                actionLabel: l10n.landingPathScrollCta,
                accentColor: xp.organizationPrimary,
                onAccentColor: xp.organizationOnPrimary,
                icon: Icons.business_outlined,
                onPressed: onCharitiesPressed,
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: LandingPathCard(
                  key: const Key('landing_guardian_path_card'),
                  summary: l10n.landingGuardianPathSummary,
                  actionLabel: l10n.landingPathScrollCta,
                  accentColor: xp.guardianPrimary,
                  onAccentColor: xp.guardianOnPrimary,
                  icon: Icons.pets,
                  onPressed: onPetParentsPressed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LandingPathCard(
                  key: const Key('landing_org_path_card'),
                  summary: l10n.landingOrgPathSummary,
                  actionLabel: l10n.landingPathScrollCta,
                  accentColor: xp.organizationPrimary,
                  onAccentColor: xp.organizationOnPrimary,
                  icon: Icons.business_outlined,
                  onPressed: onCharitiesPressed,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
