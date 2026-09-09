import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../experience/domain/entities/app_experience.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../health_tracking/presentation/widgets/add_health_entry_navigation.dart';
import '../../../../core/router/shell_return_navigation.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/care_progression_providers.dart';
import '../widgets/care_rhythms/care_rhythm_helpers.dart';
import '../widgets/care_rhythms/care_rhythm_row.dart';

/// Lists recurring established care for one pet — organisation, not intelligence.
class PetCareRhythmsScreen extends ConsumerWidget {
  const PetCareRhythmsScreen({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final experience = AppExperience.petCare;
    final entriesAsync = ref.watch(petHealthEntriesByIdProvider(petId));
    final establishmentsAsync = ref.watch(petCareEstablishmentsProvider(petId));
    final establishedIds = establishmentsAsync.maybeWhen(
      data: (establishments) => entriesAsync.maybeWhen(
        data: (entries) =>
            establishedRhythmEntryIds(establishments, filterCareRhythms(entries)),
        orElse: () => <String>{},
      ),
      orElse: () => <String>{},
    );

    void openAddRhythm() => navigateToAddHealthEntry(context, petId: petId);

    return ExperienceShellScaffold(
      experience: experience,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.careRhythmsTitle,
      backPath: petDetailBackPath(context, petId),
      contextualActions: [
        IconButton(
          key: const Key('care_rhythms_add_app_bar'),
          icon: const Icon(Icons.add),
          tooltip: l.addAnEvent,
          onPressed: openAddRhythm,
        ),
      ],
      child: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l.errorWithMessage('$error'))),
        data: (entries) {
          final rhythms = filterCareRhythms(entries);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l.careRhythmsSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: rhythms.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l.careRhythmsEmpty,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        key: const Key('care_rhythms_list'),
                        itemCount: rhythms.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = rhythms[index];
                          return CareRhythmRow(
                            entry: entry,
                            petId: petId,
                            isEstablished: establishedIds.contains(entry.id),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton.icon(
                    key: const Key('care_rhythms_add_bottom'),
                    onPressed: openAddRhythm,
                    icon: const Icon(Icons.add),
                    label: Text(l.addAnEvent),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
