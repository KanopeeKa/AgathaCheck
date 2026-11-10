import 'package:flutter/material.dart';
import 'package:pet_profile_app/core/widgets/collection_filter/org_context_collection_filter.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

export 'package:pet_profile_app/core/widgets/collection_filter/org_context_collection_filter.dart'
    show PetListOrgCollectionFilterBar;

/// Retired chip row — pet list uses [PetListOrgCollectionFilterBar] without
/// organisation or foster cohorts.
@Deprecated('Organisation/foster cohort filters removed')
class OrgFilterChips extends StatelessWidget {
  const OrgFilterChips({
    super.key,
    required this.orgNames,
    this.showFosteredChip = false,
    required this.selected,
    required this.onSelected,
    required this.l,
  });

  final List<String> orgNames;
  final bool showFosteredChip;
  final String? selected;
  final void Function(String?) onSelected;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    if (orgNames.isEmpty && !showFosteredChip) {
      return const SizedBox.shrink();
    }
    return PetListOrgCollectionFilterBar(
      orgNames: const [],
      showFosteredChoice: false,
      selectedFilter: selected,
      onFilterChanged: onSelected,
    );
  }
}
