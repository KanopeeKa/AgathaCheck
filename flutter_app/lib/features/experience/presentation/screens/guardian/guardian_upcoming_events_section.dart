import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/dashboard_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/widgets/pet_list/due_event_row.dart';

/// Due and Overdue events dashboard section — top 5 items within remind window.
class GuardianUpcomingEventsSection extends ConsumerWidget {
  const GuardianUpcomingEventsSection({super.key, required this.pets});

  final List<Pet> pets;

  static const previewLimit = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(healthEntriesNotifierProvider);

    return DashboardSection(
      title: l.dueAndOverdue,
      previewBuilder: (ctx) {
        return entriesAsync.when(
          loading: () => const SizedBox(
            height: 24,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => Text(
            l.homeNoDueEvents,
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
            ),
          ),
          data: (entries) {
            final petIds = pets.map((p) => p.id).toSet();
            final dueEntries = guardianDueEntries(entries, petIds);

            if (dueEntries.isEmpty) {
              return Text(
                l.homeNoDueEvents,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              );
            }

            final preview = dueEntries.take(previewLimit).toList();
            final petMap = {for (final p in pets) p.id: p};

            return Column(
              children: preview
                  .map(
                    (entry) => DueEventRow(
                      entry: entry,
                      pet: petMap[entry.petId],
                      showInlineActions: false,
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
      endLink: DashboardSectionLink(
        label: l.allEvents,
        onPressed: () => context.go('/g/events'),
      ),
    );
  }
}
