import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_experience.dart';
import '../providers/experience_providers.dart';

/// Default experience picker in Settings (`/g/settings` or `/o/settings`).
class ExperienceSettingsSection extends ConsumerWidget {
  const ExperienceSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final eligibility = ref.watch(experienceEligibilityProvider).valueOrNull;
    final saved = ref.watch(savedDefaultExperienceProvider);
    final store = ref.read(experiencePreferencesStoreProvider);

    if (eligibility == null || !eligibility.showChooser) {
      return const SizedBox.shrink();
    }

    final options = eligibility.availableExperiences;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.experienceDefaultSettingTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l.experienceDefaultSettingSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ...options.map((exp) {
              return RadioListTile<AppExperience>(
                key: Key('default_experience_${exp.wire}'),
                value: exp,
                groupValue: saved ?? options.first,
                title: Text(
                  exp == AppExperience.guardian
                      ? l.experienceGuardianTitle
                      : l.experienceOrganizationTitle,
                ),
                onChanged: (value) async {
                  if (value == null) return;
                  await store.writeDefaultExperience(value);
                  ref.invalidate(savedDefaultExperienceProvider);
                  ref.read(activeExperienceProvider.notifier).state = value;
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
