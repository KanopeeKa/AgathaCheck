import 'package:flutter/material.dart';
import 'package:pet_profile_app/core/widgets/collection_filter/org_context_collection_filter.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

export 'package:pet_profile_app/core/widgets/collection_filter/org_context_collection_filter.dart'
    show PetListOrgCollectionFilterBar;

/// Legacy chip row for pet list org filtering.
@Deprecated('Use PetListOrgCollectionFilterBar')
class OrgFilterChips extends StatelessWidget {
  final List<String> orgNames;
  final bool showFosteredChip;
  final String? selected;
  final void Function(String?) onSelected;
  final AppLocalizations l;

  const OrgFilterChips({
    super.key,
    required this.orgNames,
    this.showFosteredChip = false,
    required this.selected,
    required this.onSelected,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return PetListOrgCollectionFilterBar(
      orgNames: orgNames,
      showFosteredChoice: showFosteredChip,
      selectedFilter: selected,
      onFilterChanged: onSelected,
    );
  }
}
