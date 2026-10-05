import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../application/people_providers.dart';
class PersonDetailRelatedCareTab extends ConsumerWidget {
  const PersonDetailRelatedCareTab({super.key, required this.contactId});

  final String contactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final relatedAsync = ref.watch(relatedCareProvider(contactId));

    return relatedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(l.peopleListLoadError)),
      data: (related) {
        if (related == null) {
          return Center(child: Text(l.peopleDetailNotFound));
        }
        if (related.careItems.isEmpty &&
            related.absences.isEmpty &&
            related.historyCount == 0) {
          return Center(
            child: Text(
              l.peopleNoLinkedPets,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final item in related.careItems)
              ListTile(
                title: Text(item.name),
                subtitle: Text(item.petId),
              ),
            for (final absence in related.absences)
              ListTile(
                title: Text(
                  l.peopleCardLookingAfter(absence.startsOn, absence.endsOn),
                ),
                subtitle: Text(absence.petIds.join(', ')),
              ),
            if (related.historyCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l.peopleDetailRelatedCareHistory(related.historyCount)),
              ),
          ],
        );
      },
    );
  }
}
