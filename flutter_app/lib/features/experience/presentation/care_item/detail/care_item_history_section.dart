import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';

/// Resolved past occurrences and link to full history (spec §History).
class CareItemHistorySection extends ConsumerWidget {
  const CareItemHistorySection({
    super.key,
    required this.entry,
    required this.muted,
    required this.onSeeHistory,
    required this.pastOccurrencesVisibleCap,
  });

  final HealthEntry entry;
  final bool muted;
  final VoidCallback onSeeHistory;
  final int pastOccurrencesVisibleCap;

  static bool hasInlinePastOccurrences(List<HealthOccurrence> past) {
    return resolvedPastOccurrences(past).isNotEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pastAsync = ref.watch(entryPastOccurrencesProvider(entry.id));

    return CareItemModule(
      key: const Key('care_item_history_module'),
      semanticLabel: l.careItemHistoryTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CareItemSectionHeader(
            title: l.careItemHistoryTitle,
            icon: Icons.history,
          ),
          const SizedBox(height: 12),
          pastAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text(
              l.failedToLoadHistory('$error'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
              ),
            ),
            data: (past) {
              final rows = resolvedPastOccurrences(past);
              if (rows.isNotEmpty) {
                final seeFull = rows.length > pastOccurrencesVisibleCap;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CareCollectionInsetList(
                      semanticLabel: l.careItemHistoryTitle,
                      children: [
                        CareCollectionInsetItem(
                          child: PetEventPastOccurrencesSection(
                            entryId: entry.id,
                            petId: entry.petId,
                            muted: muted,
                            maxVisibleRows: pastOccurrencesVisibleCap,
                          ),
                        ),
                      ],
                    ),
                    if (seeFull) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('care_item_see_history'),
                        onPressed: onSeeHistory,
                        icon: const Icon(Icons.history),
                        label: Text(l.seeHistory),
                      ),
                    ],
                  ],
                );
              }
              return Text(
                l.noHistoryYet,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
