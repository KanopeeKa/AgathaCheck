import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../experience/domain/entities/app_experience.dart';
import '../../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../../../pet_profile/presentation/providers/care_progression_providers.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../../pet_profile/presentation/widgets/care_rhythms/care_rhythm_helpers.dart';
import '../../providers/health_providers.dart';
import '../../providers/occurrence_providers.dart';
import '../../widgets/pet_event_close_confirm_dialog.dart';
import '../../widgets/pet_event_view_providers.dart';
import '../../widgets/pet_event_lifecycle.dart';
import '../../widgets/pet_event_occurrence_actions.dart';
import '../../widgets/pet_event_view_body.dart' show showPetEventHistory;
import 'care_item_detail_body.dart';

/// Care Item detail at `/pet/:petId/events/:entryId`.
class CareItemDetailScreen extends ConsumerWidget {
  const CareItemDetailScreen({
    super.key,
    required this.petId,
    required this.entryId,
  });

  final String petId;
  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final experience = AppExperience.petCare;
    final petsAsync = ref.watch(allPetsIncludingOrgProvider);
    final entryAsync = ref.watch(
      petHealthEntryByIdProvider((petId: petId, entryId: entryId)),
    );
    final historyAsync = ref.watch(entryHistoryProvider(entryId));

    return petsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      data: (pets) {
        final pet = pets.where((p) => p.id == petId).firstOrNull;
        if (pet == null) {
          return Scaffold(body: Center(child: Text(l.petNotFound)));
        }

        return entryAsync.when(
          loading: () => ExperienceShellScaffold(
            experience: experience,
            currentLocation: GoRouterState.of(context).uri.path,
            screenTitle: l.manageEvents,
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => ExperienceShellScaffold(
            experience: experience,
            currentLocation: GoRouterState.of(context).uri.path,
            screenTitle: l.manageEvents,
            child: Center(child: Text(l.errorWithMessage('$error'))),
          ),
          data: (entry) {
            if (entry == null) {
              return ExperienceShellScaffold(
                experience: experience,
                currentLocation: GoRouterState.of(context).uri.path,
                screenTitle: l.manageEvents,
                child: Center(child: Text(l.entryNotFound)),
              );
            }

            final isClosed = isHealthEntrySeriesClosed(entry);
            final openOccurrencesAsync = ref.watch(
              entryOccurrencesProvider(entryId),
            );
            final openOccurrenceCount = openOccurrencesAsync.maybeWhen(
              data: (list) => list.length,
              orElse: () => null,
            );
            final establishmentsAsync = ref.watch(
              petCareEstablishmentsProvider(petId),
            );
            final allEntries =
                ref.watch(petHealthEntriesByIdProvider(petId)).valueOrNull ??
                const [];
            final isEstablished = establishmentsAsync.maybeWhen(
              data: (establishments) => establishedRhythmEntryIds(
                establishments,
                allEntries,
              ).contains(entry.id),
              orElse: () => false,
            );

            void onEdit() => context.push(healthEntryEditRoute(entry, petId));

            void onSeeHistory() => showPetEventHistory(context, ref, entryId);

            Future<void> onClose() async {
              if (closeEventWillCloseOccurrences(entry, openOccurrenceCount)) {
                final confirmed = await showCloseEventConfirmDialog(
                  context,
                  openOccurrenceCount: openOccurrenceCount ?? 0,
                );
                if (confirmed != true || !context.mounted) return;
              }
              await ref
                  .read(healthEntriesNotifierProvider.notifier)
                  .closeEvent(entryId);
              PetEventOccurrenceActions.invalidateOccurrenceData(ref, entryId);
            }

            Future<void> onReopen() async {
              await ref
                  .read(healthEntriesNotifierProvider.notifier)
                  .reopenEvent(entryId);
              PetEventOccurrenceActions.invalidateOccurrenceData(ref, entryId);
            }

            return ExperienceShellScaffold(
              experience: experience,
              currentLocation: GoRouterState.of(context).uri.path,
              screenTitle: l.viewEntryTitle(entry.name),
              contextualActions: [
                IconButton(
                  key: const Key('care_item_edit_app_bar'),
                  tooltip: l.edit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
                IconButton(
                  key: const Key('care_item_history_app_bar'),
                  tooltip: l.seeHistory,
                  icon: const Icon(Icons.history),
                  onPressed: onSeeHistory,
                ),
              ],
              child: historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text(l.failedToLoadHistory('$error'))),
                data: (history) => CareItemDetailBody(
                  petId: petId,
                  entry: entry,
                  pet: pet,
                  history: history,
                  isClosed: isClosed,
                  isEstablished: isEstablished,
                  onSeeHistory: onSeeHistory,
                  onClose: onClose,
                  onReopen: onReopen,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
