import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/dashboard_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/widgets/pet_list/due_event_row.dart';
import 'add_event_type_picker_sheet.dart';

/// Upcoming Pet Events dashboard section — top 5 due items preview.
class GuardianUpcomingEventsSection extends ConsumerWidget {
  const GuardianUpcomingEventsSection({super.key, required this.pets});

  final List<Pet> pets;

  static const previewLimit = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(healthEntriesNotifierProvider);

    return DashboardSection(
      title: l.upcomingPetEvents,
      headerAction: TextButton(
        onPressed: () => showAddEventTypePickerSheet(context, pets: pets),
        child: Text(l.addAnEvent),
      ),
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
            final dueEntries =
                entries
                    .where(
                      (e) =>
                          petIds.contains(e.petId) &&
                          !e.isCompleted &&
                          (e.isOverdue || e.isDueToday),
                    )
                    .toList()
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
