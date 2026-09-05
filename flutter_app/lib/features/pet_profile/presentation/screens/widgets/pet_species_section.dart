import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../widgets/pet_detail/pet_info_chip.dart';
import '../../widgets/pet_form/pet_form_labeled_field.dart';
import '../../widgets/pet_form/pet_form_species_utils.dart';

class PetSpeciesSection extends StatelessWidget {
  const PetSpeciesSection({
    super.key,
    required this.selectedSpecies,
    required this.onChanged,
  });

  final String selectedSpecies;
  final ValueChanged<String> onChanged;

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

  IconData _speciesIcon(String species) {
    switch (species) {
      case 'Dog':
        return Icons.pets;
      case 'Cat':
        return Icons.pets;
      case 'Bird':
        return Icons.flutter_dash;
      case 'Fish':
        return Icons.water;
      default:
        return Icons.pets;
    }
  }

  Future<void> _openMoreSpeciesSheet(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  l.petSpeciesMoreTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final species in morePetSpeciesOptions())
                ListTile(
                  key: Key('pet_species_more_$species'),
                  title: Text(_localizedSpecies(l, species)),
                  selected: selectedSpecies == species,
                  onTap: () => Navigator.of(context).pop(species),
                ),
            ],
          ),
        );
      },
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final normalized = normalizePetFormSpecies(selectedSpecies);
    final showMoreSelection =
        normalized.isNotEmpty && !isPrimaryPetSpecies(normalized);

    return PetFormLabeledField(
      label: l.species,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final species in primaryPetSpecies)
                _SpeciesChip(
                  key: Key('pet_species_chip_$species'),
                  label: _localizedSpecies(l, species),
                  icon: _speciesIcon(species),
                  selected: normalized == species,
                  onTap: () => onChanged(species),
                ),
              ActionChip(
                key: const Key('pet_species_more_chip'),
                avatar: const Icon(Icons.more_horiz, size: 18),
                label: Text(l.petSpeciesMore),
                onPressed: () => _openMoreSpeciesSheet(context),
              ),
            ],
          ),
          if (showMoreSelection) ...[
            const SizedBox(height: 8),
            PetInfoChip(
              icon: _speciesIcon(normalized),
              label: _localizedSpecies(l, normalized),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpeciesChip extends StatelessWidget {
  const _SpeciesChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (selected) {
      return PetInfoChip(icon: icon, label: label);
    }
    return FilterChip(
      selected: false,
      showCheckmark: false,
      label: Text(label),
      avatar: Icon(icon, size: 18),
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.secondaryContainer,
    );
  }
}
