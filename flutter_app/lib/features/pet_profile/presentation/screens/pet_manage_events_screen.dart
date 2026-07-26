import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../experience/presentation/providers/experience_providers.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../domain/services/pet_detail_actions.dart';
import '../providers/pet_detail_viewer_context_provider.dart';
import '../providers/pet_providers.dart';
import 'widgets/download_report_section.dart';
import 'widgets/health_events_section.dart';
import 'widgets/other_events_section.dart';

/// Manage pet events — Edit tab (health + other) and History tab (report PDF).
class PetManageEventsScreen extends ConsumerWidget {
  const PetManageEventsScreen({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final petsAsync = ref.watch(allPetsIncludingOrgProvider);
    final experience = ref.watch(resolvedExperienceProvider);

    return petsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      data: (pets) {
        final pet = pets.where((p) => p.id == petId).firstOrNull;
        if (pet == null) {
          return Scaffold(body: Center(child: Text(l.petNotFound)));
        }

        final viewerContext = ref.watch(petDetailViewerContextProvider(petId));
        final canDownload = viewerContext.can(PetDetailAction.downloadReport);

        return ExperienceShellScaffold(
          experience: experience,
          currentLocation: GoRouterState.of(context).uri.path,
          screenTitle: l.manageEvents,
          child: DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TabBar(
                  tabs: [
                    Tab(text: l.eventsEditTab),
                    Tab(text: l.eventsHistoryTab),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            HealthEventsSection(
                              petId: petId,
                              pet: pet,
                              flat: true,
                            ),
                            OtherEventsSection(
                              petId: petId,
                              pet: pet,
                              flat: true,
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: canDownload
                            ? DownloadReportSection(pet: pet)
                            : Text(
                                l.eventsHistoryEmpty,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
