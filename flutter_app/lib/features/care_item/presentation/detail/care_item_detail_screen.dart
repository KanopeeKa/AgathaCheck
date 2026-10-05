import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:pet_profile_app/core/experience/app_experience.dart';
import 'package:pet_profile_app/core/router/experience_shell_scaffold.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import '../widgets/care_item_history.dart';
import '../sheets/postpone_sheet.dart';
import '../sheets/resume_date_sheet.dart';
import 'care_item_detail_body.dart';
import 'care_item_menu.dart';

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
            screenTitle: l.allCareTitle(pet.name),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => ExperienceShellScaffold(
            experience: experience,
            currentLocation: GoRouterState.of(context).uri.path,
            screenTitle: l.allCareTitle(pet.name),
            child: Center(child: Text(l.errorWithMessage('$error'))),
          ),
          data: (entry) {
            if (entry == null) {
              return ExperienceShellScaffold(
                experience: experience,
                currentLocation: GoRouterState.of(context).uri.path,
                screenTitle: l.allCareTitle(pet.name),
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

            Future<void> onArchive() async {
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
              ref.invalidate(petHealthEntryByIdProvider);
            }

            Future<void> onRestore() async {
              await ref
                  .read(healthEntriesNotifierProvider.notifier)
                  .reopenEvent(entryId);
              PetEventOccurrenceActions.invalidateOccurrenceData(ref, entryId);
              ref.invalidate(petHealthEntryByIdProvider);
            }

            Future<void> onPause() async {
              final fixed =
                  entry.schedule?.isFixedSchedule ??
                  entry.recurrenceAnchor == RecurrenceAnchor.fromDueDate;
              final asOf =
                  entry.schedule?.asOf.date ?? calendarDateOnly(DateTime.now());
              final ok = await showPostponeSheet(
                context,
                ref,
                entryId: entryId,
                isFixedSchedule: fixed,
                asOf: asOf,
              );
              if (ok == true) {
                PetEventOccurrenceActions.invalidateOccurrenceData(
                  ref,
                  entryId,
                );
                ref.invalidate(petHealthEntryByIdProvider);
              }
            }

            Future<void> onResume() async {
              await ref.read(healthEntriesNotifierProvider.notifier).refresh();
              final freshEntry =
                  await ref.read(healthRepositoryProvider).getEntry(entryId) ??
                  entry;
              if (!context.mounted) return;
              final suggested =
                  freshEntry.schedule?.resumeDefaultDate ??
                  freshEntry.schedule?.asOf.date ??
                  calendarDateOnly(DateTime.now());
              final asOf =
                  freshEntry.schedule?.asOf.date ??
                  calendarDateOnly(DateTime.now());
              final ok = await showResumeDateSheet(
                context,
                ref,
                entryId: entryId,
                suggestedDate: suggested,
                asOf: asOf,
              );
              if (ok == true) {
                PetEventOccurrenceActions.invalidateOccurrenceData(
                  ref,
                  entryId,
                );
                ref.invalidate(petHealthEntryByIdProvider);
              }
            }

            return ExperienceShellScaffold(
              experience: experience,
              currentLocation: GoRouterState.of(context).uri.path,
              screenTitle: entry.name,
              contextualActions: [
                IconButton(
                  key: const Key('care_item_edit_app_bar'),
                  tooltip: l.edit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
                CareItemMenu(
                  entry: entry,
                  isClosed: isClosed,
                  onEdit: onEdit,
                  onPause: onPause,
                  onResume: onResume,
                  onArchive: onArchive,
                  onRestore: onRestore,
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
                ),
              ),
            );
          },
        );
      },
    );
  }
}
