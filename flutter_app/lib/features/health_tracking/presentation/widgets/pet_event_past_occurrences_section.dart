import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/shell_return_navigation.dart';
import 'past_occurrence_history_pill.dart';
import 'past_occurrence_history_utils.dart';
import 'pet_event_view_providers.dart';

/// Inline past occurrences (completed + skipped, newest first) for History.
class PetEventPastOccurrencesSection extends ConsumerWidget {
  const PetEventPastOccurrencesSection({
    super.key,
    required this.entryId,
    required this.muted,
    required this.maxVisibleRows,
    this.petId,
  });

  final String entryId;
  final bool muted;

  /// Inline row cap from the care item layout (3 mobile / 5 wide).
  final int maxVisibleRows;

  /// When set, each line opens its occurrence screen (§History, D-CIE-010).
  final String? petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pastAsync = ref.watch(entryPastOccurrencesProvider(entryId));

    return pastAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (past) {
        final rows = resolvedPastOccurrences(past);
        if (rows.isEmpty) return const SizedBox.shrink();

        final visible = rows.take(maxVisibleRows).toList();
        final petId = this.petId;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final occ in visible)
                PastOccurrenceHistoryPill(
                  occurrence: occ,
                  muted: muted,
                  onTap: petId == null
                      ? null
                      : () => openOccurrenceScreen(
                          context,
                          petId: petId,
                          entryId: occ.entryId,
                          occurrenceId: occ.id,
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}
