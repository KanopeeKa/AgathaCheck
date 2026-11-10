import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_experience.dart';
import '../widgets/experience_shell_scaffold.dart';

/// Invite entry point — add a pet from the Pet Care shell.
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
              Text(l.experiencePetCareInviteHint, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.push('/add'),
                child: Text(l.addPet),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
