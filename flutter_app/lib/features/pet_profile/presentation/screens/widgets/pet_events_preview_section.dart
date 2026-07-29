import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/dashboard_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../health_tracking/presentation/widgets/due_event_card.dart';
import '../../../domain/entities/pet.dart';

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
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DueEventCard(
                          entry: entry,
                          pet: pet,
                          showActions: true,
                        ),
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
