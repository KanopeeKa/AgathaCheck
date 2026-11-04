import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../widgets/all_care/all_care_closed.dart';
import '../../widgets/all_care/all_care_closed_copy.dart';
import 'closed_care_row.dart';

/// Pet-scoped list of closed care items (CARE-STATUS-R-021).
class ClosedCareListScreen extends ConsumerWidget {
  const ClosedCareListScreen({
    super.key,
    required this.petId,
    required this.onOpenEntry,
  });

  final String petId;
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

    return Scaffold(
      appBar: AppBar(title: Text(allCareClosedCareTitleLabel(l))),
      body: entriesAsync.when(
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
            child: ListView.separated(
              key: const Key('closed_care_list'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: closed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => ClosedCareRow(
                entry: closed[index],
                establishedEntryIds: establishedIds,
                onOpenEntry: onOpenEntry,
              ),
            ),
          );
        },
      ),
    );
  }
}
