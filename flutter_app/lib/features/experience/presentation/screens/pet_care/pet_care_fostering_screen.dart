import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../domain/entities/app_experience.dart';
import '../../widgets/experience_shell_scaffold.dart';
import '../../widgets/pet_care_fostering_section.dart';

/// Guardian's read-only overview of active foster relationships.
class PetCareFosteringScreen extends ConsumerWidget {
  const PetCareFosteringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final petsAsync = ref.watch(petListProvider);
    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.fosteringSessions,
      child: petsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l.error)),
        data: (pets) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: PetCareFosteringSection(pets: pets, showAll: true),
        ),
      ),
    );
  }
}
