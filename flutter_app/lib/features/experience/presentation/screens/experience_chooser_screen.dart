import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/experience_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_experience.dart';
import '../../domain/services/pet_care_onboarding_rules.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../providers/experience_providers.dart';

/// Action-oriented first-time experience after sign-up or when account is empty.
class ExperienceChooserScreen extends ConsumerWidget {
  const ExperienceChooserScreen({super.key});

  void _goPetCareOnboarding(BuildContext context, WidgetRef ref) {
    final pets = ref.read(petListProvider).valueOrNull ?? [];
    final completed = ref.read(petCareOnboardingCompletedProvider);
    final path = PetCareOnboardingRules.resolvePetCareDestination(
      targetPath: AppExperience.petCare.homePath(),
      pets: pets,
      onboardingCompleted: completed,
    );
    context.go(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = context.experienceColors;

    return Scaffold(
      appBar: AppBar(title: Text(l.ftueTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l.ftueSubtitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 24),
          _FtueActionCard(
            key: const Key('ftue_action_track_pets'),
            title: l.ftueActionTrackPetsTitle,
            subtitle: l.ftueActionTrackPetsSubtitle,
            icon: Icons.pets,
            accentColor: colors.petCarePrimary,
            onAccentColor: colors.petCareOnPrimary,
            accentContainer: colors.petCareLight,
            onTap: () => _goPetCareOnboarding(context, ref),
          ),
        ],
      ),
    );
  }
}

class _FtueActionCard extends StatelessWidget {
  const _FtueActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.accentColor,
    required this.onAccentColor,
    required this.accentContainer,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color accentColor;
  final Color onAccentColor;
  final Color accentContainer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: accentContainer.withValues(alpha: 0.65),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: accentColor),
            ],
          ),
        ),
      ),
    );
  }
}
