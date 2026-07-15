import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_experience.dart';
import '../widgets/experience_settings_section.dart';
import '../widgets/experience_shell_scaffold.dart';

/// Settings screen within an experience shell.
class ExperienceSettingsScreen extends ConsumerWidget {
  const ExperienceSettingsScreen({super.key, required this.experience});

  final AppExperience experience;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final path = GoRouterState.of(context).uri.path;

    return ExperienceShellScaffold(
      experience: experience,
      currentLocation: path,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ExperienceSettingsSection(),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(l.myDetails),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/my-details'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Invite entry point — guardian: add pet/share; org: members (phase 1 routing).
class ExperienceInviteScreen extends ConsumerWidget {
  const ExperienceInviteScreen({super.key, required this.experience});

  final AppExperience experience;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final path = GoRouterState.of(context).uri.path;

    return ExperienceShellScaffold(
      experience: experience,
      currentLocation: path,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_add_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(l.invite, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                experience == AppExperience.guardian
                    ? l.experienceGuardianInviteHint
                    : l.experienceOrganizationInviteHint,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (experience == AppExperience.guardian)
                FilledButton(
                  onPressed: () => context.push('/add'),
                  child: Text(l.addPet),
                )
              else
                FilledButton(
                  onPressed: () => context.push('/organizations'),
                  child: Text(l.myOrganizations),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
