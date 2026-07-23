import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/experience_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../organization/presentation/providers/organization_providers.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../domain/entities/app_experience.dart';
import '../../domain/services/guardian_onboarding_rules.dart';
import '../../domain/services/org_onboarding_rules.dart';
import '../providers/experience_providers.dart';

/// Post-login experience selection when user may use both shells.
class ExperienceChooserScreen extends ConsumerStatefulWidget {
  const ExperienceChooserScreen({super.key});

  @override
  ConsumerState<ExperienceChooserScreen> createState() =>
      _ExperienceChooserScreenState();
}

class _ExperienceChooserScreenState
    extends ConsumerState<ExperienceChooserScreen> {
  AppExperience? _selected;
  bool _remember = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final eligibilityAsync = ref.watch(experienceEligibilityProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.experienceChooserTitle)),
      body: eligibilityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.failedToLoadPets(e.toString()))),
        data: (eligibility) {
          final options = eligibility.availableExperiences;
          _selected ??= options.first;
          final showRemember = eligibility.showChooser;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                l.experienceChooserSubtitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              if (options.contains(AppExperience.guardian))
                _ExperienceCard(
                  key: const Key('experience_card_guardian'),
                  title: l.experienceGuardianTitle,
                  subtitle: l.experienceGuardianSubtitle,
                  icon: Icons.pets,
                  selected: _selected == AppExperience.guardian,
                  accentColor: context.experienceColors.guardianPrimary,
                  onAccentColor: context.experienceColors.guardianOnPrimary,
                  accentContainer: context.experienceColors.guardianLight,
                  onTap: () =>
                      setState(() => _selected = AppExperience.guardian),
                ),
              if (options.contains(AppExperience.organization)) ...[
                const SizedBox(height: 12),
                _ExperienceCard(
                  key: const Key('experience_card_organization'),
                  title: l.experienceOrganizationTitle,
                  subtitle: l.experienceOrganizationSubtitle,
                  icon: Icons.business,
                  selected: _selected == AppExperience.organization,
                  accentColor: context.experienceColors.organizationPrimary,
                  onAccentColor: context.experienceColors.organizationOnPrimary,
                  accentContainer: context.experienceColors.organizationLight,
                  onTap: () =>
                      setState(() => _selected = AppExperience.organization),
                ),
              ],
              const SizedBox(height: 12),
              _ExperienceCard(
                key: const Key('experience_card_boarding'),
                title: l.experienceBoardingTitle,
                subtitle: l.experienceBoardingSubtitle,
                icon: Icons.house_siding_outlined,
                selected: false,
                enabled: false,
                accentColor: theme.colorScheme.outline,
                onAccentColor: theme.colorScheme.onSurface,
                accentContainer: theme.colorScheme.surfaceContainerHighest,
                onTap: () {},
              ),
              if (showRemember) ...[
                const SizedBox(height: 24),
                CheckboxListTile(
                  key: const Key('remember_experience_choice'),
                  value: _remember,
                  onChanged: (v) => setState(() => _remember = v ?? false),
                  title: Text(l.experienceRememberChoice),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                Semantics(
                  container: true,
                  label: l.experienceRememberChoiceHint,
                  child: Container(
                    key: const Key('remember_experience_hint'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.experienceRememberChoiceHint,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                key: const Key('experience_continue_button'),
                onPressed: _selected == null
                    ? null
                    : () => _continue(context, _selected!),
                child: Text(l.continueButton),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _continue(BuildContext context, AppExperience experience) async {
    final store = ref.read(experiencePreferencesStoreProvider);
    if (_remember) {
      await store.writeDefaultExperience(experience);
    } else {
      await store.clear();
    }
    ref.read(activeExperienceProvider.notifier).state = experience;
    if (!context.mounted) return;
    var path = experience.homePath();
    if (experience == AppExperience.guardian) {
      final pets = ref.read(petListProvider).valueOrNull ?? [];
      final completed = ref.read(guardianOnboardingCompletedProvider);
      path = GuardianOnboardingRules.resolveGuardianDestination(
        targetPath: path,
        pets: pets,
        onboardingCompleted: completed,
      );
    } else if (experience == AppExperience.organization) {
      final pets = ref.read(petListProvider).valueOrNull ?? [];
      final orgs = ref.read(organizationListProvider).valueOrNull ?? [];
      final completed = ref.read(orgOnboardingCompletedProvider);
      path = OrgOnboardingRules.resolveOrgDestination(
        targetPath: path,
        pets: pets,
        orgs: orgs,
        onboardingCompleted: completed,
      );
    }
    context.go(path);
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.accentColor,
    required this.onAccentColor,
    required this.accentContainer,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final Color accentColor;
  final Color onAccentColor;
  final Color accentContainer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = selected
        ? accentColor
        : theme.colorScheme.outlineVariant;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: selected
            ? accentContainer.withValues(alpha: 0.65)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: selected ? 2 : 1),
            ),
            child: Row(
              children: [
                Icon(icon, size: 36, color: accentColor),
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
                if (selected) Icon(Icons.check_circle, color: accentColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
