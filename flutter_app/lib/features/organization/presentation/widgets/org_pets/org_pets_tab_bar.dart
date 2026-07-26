import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/experience_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../providers/org_pets_screen_providers.dart';
import '../../utils/org_pets_care_utils.dart';

class OrgPetsTabBar extends ConsumerWidget {
  const OrgPetsTabBar({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final selected = ref.watch(orgPetsTabProvider(orgId));
    final xp = context.experienceColors;
    final tabs = <(OrgPetsTab, String)>[
      (OrgPetsTab.needAttention, l.orgPetsTabNeedAttention),
      (OrgPetsTab.inFoster, l.orgPetsTabInFoster),
      (OrgPetsTab.adopted, l.orgPetsTabAdopted),
      (OrgPetsTab.all, l.orgPetsTabAll),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          for (final (tab, label) in tabs)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OrgPetsFilterChip(
                key: Key('org_pets_tab_${tab.name}'),
                label: label,
                selected: selected == tab,
                accentColor: xp.organizationPrimary,
                onTap: () {
                  ref.read(orgPetsTabProvider(orgId).notifier).state = tab;
                },
              ),
            ),
        ],
      ),
    );
  }
}

class OrgPetsFilterChip extends StatelessWidget {
  const OrgPetsFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: accentColor.withAlpha(40),
      checkmarkColor: accentColor,
      labelStyle: TextStyle(
        color: selected ? accentColor : null,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: selected ? BorderSide(color: accentColor, width: 1.5) : null,
    );
  }
}
