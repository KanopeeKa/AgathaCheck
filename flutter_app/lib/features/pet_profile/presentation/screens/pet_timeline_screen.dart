import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../experience/presentation/providers/experience_providers.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../providers/pet_providers.dart';
import '../providers/pet_timeline_providers.dart';
import '../widgets/pet_timeline/pet_timeline_view.dart';
import '../widgets/pet_timeline/pet_timeline_fill_sheet.dart';

/// Dedicated pet timeline screen (vertical spine; custody/gap fill deferred).
class PetTimelineScreen extends ConsumerWidget {
  const PetTimelineScreen({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final experience = ref.watch(resolvedExperienceProvider);
    final petAsync = ref.watch(petByIdProvider(petId));
    final timelineAsync = ref.watch(petTimelineListProvider(petId));

    final petName = petAsync.maybeWhen(
      data: (pet) => pet?.name ?? '',
      orElse: () => '',
    );

    void openAddSheet() {
      if (petName.isEmpty) return;
      showPetTimelineFillSheet(context, ref, petId: petId, petName: petName);
    }

    return ExperienceShellScaffold(
      experience: experience,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.petTimelineTitle,
      contextualActions: [
        IconButton(
          key: const Key('pet_timeline_add_app_bar'),
          icon: const Icon(Icons.add),
          tooltip: l.addAnEvent,
          onPressed: petName.isEmpty ? null : openAddSheet,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: timelineAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l.petTimelineLoadError,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l.petTimelineNoData,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return PetTimelineView(
                  segments: entries,
                  petId: petId,
                  petName: petName,
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton.icon(
                key: const Key('pet_timeline_add_bottom'),
                onPressed: petName.isEmpty ? null : openAddSheet,
                icon: const Icon(Icons.add),
                label: Text(l.addAnEvent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
