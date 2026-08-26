import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/utils/constants.dart';

class PetSpeciesSection extends StatelessWidget {
  final String selectedSpecies;
  final ValueChanged<String> onChanged;

  const PetSpeciesSection({
    super.key,
    required this.selectedSpecies,
    required this.onChanged,
  });

  String _localizedSpecies(AppLocalizations l, String species) {
    switch (species) {
      case 'Dog':
        return l.speciesDog;
      case 'Cat':
        return l.speciesCat;
      case 'Bird':
        return l.speciesBird;
      case 'Fish':
        return l.speciesFish;
      case 'Rabbit':
        return l.speciesRabbit;
      case 'Hamster':
        return l.speciesHamster;
      case 'Ferret':
        return l.speciesFerret;
      case 'Horse / Poney':
        return l.speciesHorsePoney;
      case 'Other':
        return l.speciesOther;
      default:
        return species;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String>(
      key: const Key('pet_species_field'),
      initialValue: selectedSpecies.isEmpty ? null : selectedSpecies,
      decoration: InputDecoration(
        labelText: l.species,
        helperText: 'Select the type of animal',
      ),
      items: AppConstants.species
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(_localizedSpecies(l, s)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
