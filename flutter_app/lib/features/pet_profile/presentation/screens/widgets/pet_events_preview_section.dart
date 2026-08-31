import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/dashboard_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../health_tracking/presentation/widgets/care_event_row.dart';
import '../../../../health_tracking/presentation/widgets/care_event_row_context.dart';
import '../../../domain/entities/pet.dart';
import '../../widgets/pet_list/home_event_actions.dart';

/// Pet profile due/overdue preview with link to manage events.
class PetEventsPreviewSection extends ConsumerWidget {
  const PetEventsPreviewSection({
    super.key,
    required this.petId,
    required this.pet,
  });

  final String petId;
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(petHealthEntriesByIdProvider(petId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DashboardSection(
        title: l.dueAndOverdue,
        previewBuilder: (ctx) {
          return entriesAsync.when(
            loading: () => const SizedBox(
              height: 24,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (error, _) => Text(
              l.errorLoadingEntries(error.toString()),
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: Theme.of(ctx).colorScheme.error,
              ),
            ),
            data: (entries) {
              final dueEntries = entries.where(isEntryDueOrOverdue).toList()
                ..sort((a, b) {
                  final ad = a.nextDueDate ?? DateTime(2100);
                  final bd = b.nextDueDate ?? DateTime(2100);
                  return ad.compareTo(bd);
                });

              if (dueEntries.isEmpty) {
                return Text(
                  l.homeNoDueEvents,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                );
              }

              return Column(
                children: dueEntries
                    .map(
                      (entry) => CareEventRow(
                        key: Key('pet_preview_care_row_${entry.id}'),
                        entry: entry,
                        pet: pet,
                        rowContext: CareEventRowContext.pet,
                        isCompleted: false,
                        onMarkDone: () =>
                            HomeEventActions.markDone(context, ref, entry),
                        onUndo: () {},
                        onView: () =>
                            HomeEventActions.viewEntry(context, entry),
                      ),
                    )
                    .toList(),
              );
            },
          );
        },
        endLink: DashboardSectionLink(
          label: l.manageEvents,
          onPressed: () => context.push('/pet/$petId/events'),
        ),
      ),
    );
  }
}
