import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class OrgFilterChips extends StatelessWidget {
  final List<String> orgNames;
  final String? selected;
  final void Function(String?) onSelected;
  final AppLocalizations l;

  const OrgFilterChips({
    super.key,
    required this.orgNames,
    required this.selected,
    required this.onSelected,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text(l.allPets),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          ChoiceChip(
            label: Text(l.myPets),
            selected: selected == '_personal',
            onSelected: (_) => onSelected('_personal'),
          ),
          ...orgNames.map((org) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(org),
                  selected: selected == org,
                  onSelected: (_) => onSelected(org),
                ),
              )),
        ],
      ),
    );
  }
}
