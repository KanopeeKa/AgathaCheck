import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../experience/presentation/providers/experience_providers.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';

/// Dedicated health issues screen — content lands in phase 8–9.
class PetHealthIssuesScreen extends ConsumerWidget {
  const PetHealthIssuesScreen({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final experience = ref.watch(resolvedExperienceProvider);
    final theme = Theme.of(context);

    return ExperienceShellScaffold(
      experience: experience,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.healthIssues,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l.experienceBoardingSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
