import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../data/utils/pet_profile_normalize.dart';
import '../../widgets/pet_form/pet_form_labeled_field.dart';

enum PetSexSelection { female, male, unknown }

PetSexSelection? petSexSelectionFromGender(String? gender) {
  final normalized = normalizePetGender(gender);
  if (normalized == 'Female') return PetSexSelection.female;
  if (normalized == 'Male') return PetSexSelection.male;
  return PetSexSelection.unknown;
}

String? petGenderFromSexSelection(PetSexSelection? selection) {
  return switch (selection) {
    PetSexSelection.female => 'Female',
    PetSexSelection.male => 'Male',
    PetSexSelection.unknown => null,
    null => null,
  };
}

class PetGenderSection extends StatelessWidget {
  const PetGenderSection({
    super.key,
    required this.selectedGender,
    required this.onChanged,
  });

  final String? selectedGender;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final selection = petSexSelectionFromGender(selectedGender);

    return PetFormLabeledField(
      label: l.petSexLabel,
      child: SegmentedButton<PetSexSelection>(
        key: const Key('pet_gender_field'),
        segments: [
          ButtonSegment(
            value: PetSexSelection.female,
            label: Text(l.petSexFemale),
          ),
          ButtonSegment(
            value: PetSexSelection.male,
            label: Text(l.petSexMale),
          ),
          ButtonSegment(
            value: PetSexSelection.unknown,
            label: Text(l.petSexUnknown),
          ),
        ],
        selected: {selection ?? PetSexSelection.unknown},
        onSelectionChanged: (values) {
          onChanged(petGenderFromSexSelection(values.first));
        },
      ),
    );
  }
}
