import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../widgets/all_care/all_care_closed.dart';
import '../../widgets/all_care/all_care_closed_copy.dart';
import 'closed_care_row.dart';

/// Closed care rows on the All care route (CARE-STATUS-R-021).
class ClosedCareListBody extends ConsumerWidget {
  const ClosedCareListBody({
    super.key,
    required this.petId,
    required this.onBack,
    required this.onOpenEntry,
  });

  final String petId;
  final VoidCallback onBack;
  final void Function(HealthEntry entry) onOpenEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(petHealthEntriesByIdProvider(petId));
    final establishedIds = ref
        .watch(petCareEstablishmentsProvider(petId))
        .maybeWhen(
          data: (establishments) {
            final all = entriesAsync.valueOrNull ?? const [];
            return establishedRhythmEntryIds(establishments, all);
          },
          orElse: () => <String>{},
        );

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(l.errorWithMessage('$error'))),
      data: (entries) {
        final closed = partitionClosedCareEntries(entries);
        if (closed.isEmpty) {
          return Center(child: Text(allCareClosedCareEmptyLabel(l)));
        }
        return Semantics(
          identifier: 'closed_care_list',
          container: true,
          child: ListView(
            key: const Key('closed_care_list'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  identifier: 'all_care_closed_back',
                  button: true,
                  child: TextButton(
                    key: const Key('all_care_closed_back'),
                    onPressed: onBack,
                    child: Text(l.allCareTitle('')),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  allCareClosedCareTitleLabel(l),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (var i = 0; i < closed.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                ClosedCareRow(
                  entry: closed[i],
                  establishedEntryIds: establishedIds,
                  onOpenEntry: onOpenEntry,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
