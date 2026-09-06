import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/experience_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_experience.dart';
import '../../domain/services/pet_care_onboarding_rules.dart';
import '../../domain/services/org_onboarding_rules.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../organization/presentation/providers/organization_providers.dart';
import '../providers/experience_providers.dart';

/// Action-oriented first-time experience after sign-up or when account is empty.
class ExperienceChooserScreen extends ConsumerWidget {
  const ExperienceChooserScreen({super.key});

  Future<void> _showFosteringDialog(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final codeController = TextEditingController();
    final code = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.ftueFosteringDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.ftueFosteringDialogBody),
            const SizedBox(height: 16),
            TextField(
              key: const Key('ftue_foster_code_field'),
              controller: codeController,
              decoration: InputDecoration(
                labelText: l.inviteCode,
                hintText: l.enterInviteCode,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) =>
                  Navigator.pop(ctx, codeController.text.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('ftue_foster_continue_button'),
            onPressed: () => Navigator.pop(ctx, codeController.text.trim()),
            child: Text(l.continueButton),
          ),
        ],
      ),
    );
    codeController.dispose();
    if (!context.mounted) return;
    if (code != null && code.isNotEmpty) {
      context.go('/shared/$code');
      return;
    }
    context.go('/pc/home');
  }

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

  void _goShelterOnboarding(BuildContext context, WidgetRef ref) {
    final pets = ref.read(petListProvider).valueOrNull ?? [];
    final orgs = ref.read(organizationListProvider).valueOrNull ?? [];
    final completed = ref.read(orgOnboardingCompletedProvider);
    final path = OrgOnboardingRules.resolveOrgDestination(
      targetPath: AppExperience.organization.homePath(),
      pets: pets,
      orgs: orgs,
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
          const SizedBox(height: 12),
          _FtueActionCard(
            key: const Key('ftue_action_run_shelter'),
            title: l.ftueActionRunShelterTitle,
            subtitle: l.ftueActionRunShelterSubtitle,
            icon: Icons.business_outlined,
            accentColor: colors.organizationPrimary,
            onAccentColor: colors.organizationOnPrimary,
            accentContainer: colors.organizationLight,
            onTap: () => _goShelterOnboarding(context, ref),
          ),
          const SizedBox(height: 12),
          _FtueActionCard(
            key: const Key('ftue_action_fostering'),
            title: l.ftueActionFosteringTitle,
            subtitle: l.ftueActionFosteringSubtitle,
            icon: Icons.home_outlined,
            accentColor: theme.colorScheme.tertiary,
            onAccentColor: theme.colorScheme.onTertiary,
            accentContainer: theme.colorScheme.tertiaryContainer,
            onTap: () => _showFosteringDialog(context),
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
