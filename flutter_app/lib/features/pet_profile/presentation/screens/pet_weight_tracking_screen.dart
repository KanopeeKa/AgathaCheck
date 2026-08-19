import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import 'widgets/weight_tracking_section.dart';
import '../../../experience/domain/entities/app_experience.dart';

/// Dedicated weight tracking screen for a pet.
class PetWeightTrackingScreen extends ConsumerWidget {
  const PetWeightTrackingScreen({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final experience = AppExperience.guardian;

    void onAddEntry() => openAddWeightEntrySheet(context, ref, petId);

    return ExperienceShellScaffold(
      experience: experience,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.weightTracking,
      contextualActions: [
        IconButton(
          key: const Key('weight_tracking_add_app_bar'),
          tooltip: l.addWeightEntry,
          icon: const Icon(Icons.add),
          onPressed: onAddEntry,
        ),
      ],
      child: SingleChildScrollView(
        child: WeightTrackingContent(petId: petId, onAddEntry: onAddEntry),
      ),
    );
  }
}
