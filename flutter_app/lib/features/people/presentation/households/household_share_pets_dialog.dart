import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';

/// G5: after accepting a household invite, optionally share owned pets (none pre-selected).
Future<List<String>?> showHouseholdSharePetsAfterInviteDialog({
  required BuildContext context,
  required String householdName,
  required List<Pet> ownedPets,
}) {
  if (ownedPets.isEmpty) return Future.value(const []);
  return showDialog<List<String>>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _HouseholdSharePetsDialog(
      householdName: householdName,
      ownedPets: ownedPets,
    ),
  );
}

class _HouseholdSharePetsDialog extends StatefulWidget {
  const _HouseholdSharePetsDialog({
    required this.householdName,
    required this.ownedPets,
  });

  final String householdName;
  final List<Pet> ownedPets;

  @override
  State<_HouseholdSharePetsDialog> createState() =>
      _HouseholdSharePetsDialogState();
}

class _HouseholdSharePetsDialogState extends State<_HouseholdSharePetsDialog> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        l.peopleHouseholdSharePetsAfterInviteTitle(widget.householdName),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.peopleHouseholdSharePetsAfterInviteBody),
            const SizedBox(height: 12),
            for (final pet in widget.ownedPets)
              CheckboxListTile(
                key: Key('household_share_pet_${pet.id}'),
                value: _selected.contains(pet.id),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selected.add(pet.id);
                    } else {
                      _selected.remove(pet.id);
                    }
                  });
                },
                title: Text(pet.name),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('household_share_pets_skip'),
          onPressed: () => Navigator.pop(context, const []),
          child: Text(l.peopleHouseholdSharePetsSkip),
        ),
        FilledButton(
          key: const Key('household_share_pets_confirm'),
          onPressed: () => Navigator.pop(context, _selected.toList()),
          child: Text(l.continueButton),
        ),
      ],
    );
  }
}
