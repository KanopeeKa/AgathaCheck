import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/collection_filter/org_pets_collection_filter.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../providers/org_pets_screen_providers.dart';
import '../../utils/org_pets_care_utils.dart';

class OrgPetsFilterRow extends ConsumerWidget {
  const OrgPetsFilterRow({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final filters = ref.watch(orgPetsFilterProvider(orgId));
    final filterNotifier = ref.read(orgPetsFilterProvider(orgId).notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrgPetsRefinementCollectionFilterBar(
            activeFilters: filters.activeFilters,
            onActiveFiltersChanged: (next) {
              filterNotifier.state = filters.copyWith(activeFilters: next);
            },
          ),
          if (filters.nameFilterEnabled) ...[
            const SizedBox(height: 8),
            TextField(
              key: const Key('org_pets_name_search'),
              decoration: InputDecoration(
                labelText: l.orgPetsFilterNameHint,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                filterNotifier.state = filters.copyWith(nameQuery: value);
              },
            ),
          ],
          if (filters.fosteredByFilterEnabled) ...[
            const SizedBox(height: 8),
            TextField(
              key: const Key('org_pets_fostered_by_search'),
              decoration: InputDecoration(
                labelText: l.orgPetsFilterFosteredByHint,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                filterNotifier.state = filters.copyWith(fosteredByQuery: value);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class OrgPetsNeedAttentionHelp extends StatelessWidget {
  const OrgPetsNeedAttentionHelp({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Tooltip(
          key: const Key('org_pets_need_attention_tooltip'),
          message: l.orgPetsNeedAttentionTooltip,
          child: Semantics(
            identifier: 'org_pets_need_attention_tooltip',
            child: Icon(
              Icons.info_outline,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

String localizedAttentionReason(
  AppLocalizations l,
  OrgPetAttentionReason reason,
) {
  return switch (reason) {
    OrgPetAttentionReason.notInFoster => l.orgPetsNeedAttentionNotInFoster,
    OrgPetAttentionReason.fosterFinishingSoon =>
      l.orgPetsNeedAttentionFosterFinishingSoon,
  };
}
