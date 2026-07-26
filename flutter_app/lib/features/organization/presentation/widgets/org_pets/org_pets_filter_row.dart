import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/experience_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../providers/org_pets_screen_providers.dart';
import '../../utils/org_pets_care_utils.dart';
import 'org_pets_tab_bar.dart';

class OrgPetsFilterRow extends ConsumerWidget {
  const OrgPetsFilterRow({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final xp = context.experienceColors;
    final filters = ref.watch(orgPetsFilterProvider(orgId));
    final filterNotifier = ref.read(orgPetsFilterProvider(orgId).notifier);

    void toggleFilter(OrgPetsActiveFilter filter) {
      final next = Set<OrgPetsActiveFilter>.from(filters.activeFilters);
      if (next.contains(filter)) {
        next.remove(filter);
      } else {
        next.add(filter);
      }
      filterNotifier.state = filters.copyWith(activeFilters: next);
    }

    final chips = <(OrgPetsActiveFilter, String, Key)>[
      (
        OrgPetsActiveFilter.name,
        l.orgPetsFilterName,
        const Key('org_pets_filter_name'),
      ),
      (
        OrgPetsActiveFilter.fosteredBy,
        l.orgPetsFilterFosteredBy,
        const Key('org_pets_filter_fostered_by'),
      ),
      (
        OrgPetsActiveFilter.shadow,
        l.orgPetsFilterShadow,
        const Key('org_pets_filter_shadow'),
      ),
      (
        OrgPetsActiveFilter.rainbowBridge,
        l.orgPetsFilterRainbowBridge,
        const Key('org_pets_filter_rainbow_bridge'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.orgPetsFiltersLabel, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final (filter, label, key) in chips)
                OrgPetsFilterChip(
                  key: key,
                  label: label,
                  selected: filters.activeFilters.contains(filter),
                  accentColor: xp.organizationPrimary,
                  onTap: () => toggleFilter(filter),
                ),
            ],
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
          child: Icon(
            Icons.info_outline,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
