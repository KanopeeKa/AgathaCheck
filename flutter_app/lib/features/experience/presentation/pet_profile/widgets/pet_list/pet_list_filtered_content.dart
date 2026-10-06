import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../widgets/organization_pets_section.dart';

/// List sections for pets after org/foster filtering (standalone shell).
class PetListFilteredContent extends StatelessWidget {
  const PetListFilteredContent({
    super.key,
    required this.filteredPets,
    required this.orgNames,
    required this.hasFosteredPets,
    required this.orgFilter,
    required this.onOrgFilterChanged,
    required this.controller,
    required this.l,
    required this.theme,
    required this.ref,
    required this.parentContext,
  });

  final List<Pet> filteredPets;
  final List<String> orgNames;
  final bool hasFosteredPets;
  final String? orgFilter;
  final ValueChanged<String?> onOrgFilterChanged;
  final PetListController controller;
  final AppLocalizations l;
  final ThemeData theme;
  final WidgetRef ref;
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    final personalActive = controller.getPersonalActive(filteredPets);
    final personalPassed = controller.getPersonalPassed(filteredPets);
    final fosteredActive = controller.getFosteredActive(filteredPets);
    final fosteredPassed = controller.getFosteredPassed(filteredPets);
    final orgGroups = controller.getOrgGroups(filteredPets);
    final orgPassedGroups = controller.getOrgPassedGroups(filteredPets);
    final allPassedAway = controller.getAllPassedAway(
      personalPassed,
      fosteredPassed,
      orgPassedGroups,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (orgNames.isNotEmpty || hasFosteredPets)
          OrgFilterChips(
            orgNames: orgNames,
            showFosteredChip: hasFosteredPets,
            selected: orgFilter,
            onSelected: onOrgFilterChanged,
            l: l,
          ),
        const PendingFosterPlacementsSection(),
        const PendingAdoptionPlacementsSection(),
        const PendingCustodyTransfersSection(),
        if (orgFilter == null || orgFilter == '_personal') ...[
          if (personalActive.isNotEmpty ||
              (orgFilter == null &&
                  (fosteredActive.isNotEmpty || orgGroups.isNotEmpty)))
            PetListSectionHeader(
              icon: Icons.person,
              title: l.myPets,
              count: personalActive.length,
            ),
          PersonalPetsSection(
            personalActive: personalActive,
            orgFilter: orgFilter,
            l: l,
            theme: theme,
            ref: ref,
            parentContext: parentContext,
          ),
        ],
        if (orgFilter == null || orgFilter == '_fostered') ...[
          if (fosteredActive.isNotEmpty || orgFilter == '_fostered')
            PetListSectionHeader(
              icon: Icons.home_work_outlined,
              title: l.myFosteredPets,
              count: fosteredActive.length,
            ),
          FosteredPetsSection(
            fosteredActive: fosteredActive,
            orgFilter: orgFilter,
            l: l,
            theme: theme,
          ),
        ],
        if (orgFilter == null ||
            (orgFilter != '_personal' && orgFilter != '_fostered'))
          OrganizationPetsSection(
            orgGroups: orgGroups,
            l: l,
            theme: theme,
            ref: ref,
            parentContext: parentContext,
          ),
        PassedAwayPetsSection(allPassedAway: allPassedAway, theme: theme),
      ],
    );
  }
}
